from instr_db import uses_memory, is_io, may_go_on
import subprocess
import sys
import html

def create_instruction(fields, address, label_sub):
    global uses_memory, is_io, may_go_on
    alignment = int(address[9], 16)
    mnemonic = fields[0]
    targets = []
    xta_endpoints = []
    args = ''
    for i in fields:
        if i.startswith('<'):
            if i.startswith('<xta_'):
                continue
            if i in label_sub:
                t = label_sub[i]
            else:
                t = i
            if not t in targets:
                targets += [t]
            args += ' ' + i
            continue
        if i.startswith('{'):
            xta_endpoints += [i]
            continue
        if args == '':
            args += '%-8s' % (i)
        elif i.startswith('('):
            pass
        elif i.startswith('NOPAUSE'):
            pass
        else:
            args += ' ' + i
    instr = {
             'cycles': 0,
             'buf_before': 0,
             'memory' : uses_memory[mnemonic],
             'io' : is_io[mnemonic] and not 'NOPAUSE' in fields,
             'may_go_on': may_go_on[mnemonic],
             'mnemonic' : mnemonic,
             'address' : address,
             'args' : args,
             'alignment' : alignment,
             'xta_endpoints' : xta_endpoints,
             'targets': targets}
    return instr

def combine_halfs(a, b):
    if a['mnemonic'] == 'nop':
        m = b['mnemonic']
    elif b['mnemonic'] == 'nop':
        m = a['mnemonic']
    else:
        m = a['mnemonic'] + '; ' + b['mnemonic']
    instr = {
             'cycles': 0,
             'buf_before': 0,
             'memory' : a['memory'] or b['memory'],
             'io' : a['io'] or b['io'],
             'may_go_on' : a['may_go_on'] and b['may_go_on'],
             'mnemonic': m,
             'address' : a['address'],
             'args' : '%-30s; %-30s'  % (a['args'],b['args']),
             'alignment' : a['alignment'],
             'xta_endpoints': a['xta_endpoints'] + b['xta_endpoints'],
             'targets': a['targets'] + b['targets']}
    return instr

def add_instruction(ilist, label, instruction):
    if label in ilist:
        l = ilist[label]
    else:
        l = []
    ilist[label] = l + [instruction]
    return ilist

def calc_bb_timings(ilist):
    for n in ilist:
        instrs = ilist[n]
        ibuffer_fullness = (16 - instrs[0]['alignment'])//4
        cnt = 0
        insert_fnop = []
        for j in instrs:
            if ibuffer_fullness == 0:
                ibuffer_fullness += 4
                insert_fnop = [cnt] + insert_fnop
                pass
            j['buf_before'] = ibuffer_fullness
            if not j['memory']:
                if ibuffer_fullness <= 4:
                    ibuffer_fullness += 4
            ibuffer_fullness -= 1
            cnt += 1
        for j in insert_fnop:
            instrs = instrs[0:j] + [create_instruction(['fnop'],'0x00000000',{})] + instrs[j:]
        ilist[n] = instrs

    for n in ilist:
        instrs = ilist[n]
        cycles = 0
        for j in instrs:
            if j['mnemonic'].startswith('wait'):
                cycles += 2
            else:
                cycles += 1
            j['cycles'] = cycles

def register_new_path(paths, cycle_count, depth, label, inum, endpoint, instrname, path):
    endpoint = (label, inum, endpoint)
    if endpoint not in paths:
        paths[endpoint] = []
    epdata = paths[endpoint]
    epdata += [{'cycles': cycle_count,
                'depth' : depth,
                'endinstr' : instrname,
                'path': path}]

def explore_depth_first(ilist, label, inum, cycle_count, depth, path, start, paths, ibuffer_fullness):
    if depth > 10:
        register_new_path(paths, cycle_count, depth, label, inum, None, 'Fail', path)
        return
    instrs = ilist[label]
    if ibuffer_fullness < 0:
        ibuffer_fullness = (16 - instrs[0]['alignment'])//4
    while inum < len(instrs):
        pre_fullness = ibuffer_fullness
        if ibuffer_fullness == 0:
            ibuffer_fullness += 4
            cycle_count += 1
        if instrs[inum]['mnemonic'] != 'buwc':
            cycle_count += 1
            if not instrs[inum]['memory']:
                if ibuffer_fullness <= 4:
                    ibuffer_fullness += 4
            ibuffer_fullness -= 1
        path = path + [(label, inum, cycle_count, pre_fullness, instrs[0]['alignment'])]
        if instrs[inum]['mnemonic'].startswith('wait'):
            cycle_count += 1
        if instrs[inum]['io'] and not start:
            endpoint = None
            if instrs[inum]['xta_endpoints'] != []:
                endpoint = instrs[inum]['xta_endpoints'][0]
            register_new_path(paths, cycle_count, depth, label, inum, endpoint, instrs[inum]['mnemonic'], path)
            return
        for i in instrs[inum]['targets']:
            new_ibuffer_fullness = -1
            if instrs[inum]['mnemonic'] == 'buwc':
                new_ibuffer_fullness = ibuffer_fullness
            explore_depth_first(ilist, i, 0, cycle_count, depth+1, path , False, paths,
                                    new_ibuffer_fullness )
        if not instrs[inum]['may_go_on']:
            for k in range(inum+1, len(instrs)):
                if (instrs[k]['mnemonic'] == 'nop' or
                    instrs[k]['mnemonic'] == 'fnop' or
                    instrs[k]['mnemonic'] == 'buwc' or
                    instrs[k]['mnemonic'] == 'stw; stw'):
                    continue
                print('ERROR: Dead code ', instrs[k]['mnemonic'], 'in', label)
            inum = len(instrs)-1
            break
        inum += 1
        start = False
    if inum != len(instrs)-1:
        print('ERROR: Walked out in ', label)
        
def pretty_print_ilist(ilist):
    for n in ilist:
        print(n)
        for j in ilist[n]:
            print('    ', j)
        
def pretty_print_paths(n, paths, constraints, constrained_paths, c_out):
    for p in paths:
        cycles = 0
        for pp in paths[p]:
            cycles = max(cycles, pp['cycles'])
        if n[2] is not None:
            name = n[2]
        else:
            name = '[' + n[0] + ':' + str(n[1]) + ']'
        if p[2] is not None:
            pame = p[2]
        else:
            pame = '[' + p[0] + ':' + str(p[1]) + ']'
        index = (name, pame)
        if index in constraints:
            ns = constraints.pop(index)
            constrained_paths += [((1000.0 / (ns/(8*cycles))),
                                  '%-30s => %-30s (%d cycles)' % (name,pame,cycles), paths[p])]
            continue
        c_out += '<li><tt>' + str(name).replace('<', '').replace('>','') + '&nbsp</tt>&#8658;<tt>&nbsp;'+ str(pame).replace('<', '').replace('>','') + '&nbsp;</tt>\n<br/>'
        for pp in paths[p]:
            ppp = pp['path']
            c_out += '\n' + str(pp['cycles']) + ' cycles:'
            for pppp in ppp:
                c_out += '<tt>[' + pppp[0].replace('<', '').replace('>','') +':' + str(pppp[1]) + ']</tt>, '
        c_out += '</li>'
    return (constrained_paths, c_out)

def may_carry_on(instrs):
    return instrs[len(instrs)-1]['may_go_on']

def read_constraints():
    constraints = {}
    with open('constraints.txt', 'r') as fd:
        lines = fd.readlines()
    for i in lines:
        fields = i.split()
        if 'ns' in fields:
            ns = float(fields[0])
            continue
        if len(fields) == 2:
            index = (fields[0], fields[1])
            if index in constraints:
                print('ERROR: duplicate constraint ' , index)
            constraints[index] = ns
    return constraints


def read_binary(filename):
    lines = subprocess.check_output(['xobjdump', '-d', filename]).splitlines()
    parsing = False
    ilist = {}
    label = None
    added_to_next_statement = ''
    last_was_label = False
    label_sub = {}
    newlines = []
    for l in lines:
        clean = l.decode('ascii').strip()
        if clean == '':
            continue
        if not parsing:
            if clean == '<xta_start>:':
                parsing = True
            continue
        if clean == '<xta_end>:':
            break
        if clean.startswith('<xta_'):
            if clean.startswith('<xta_no_pause'):
                added_to_next_statement = ' NOPAUSE'
                continue
            if clean.startswith('<xta_target'):
                index = clean.find('_', 5)
                added_to_next_statement += ' <' + clean[index+1:len(clean)-2] + '>'
                continue
            if clean.startswith('<xta_ep_'):
                added_to_next_statement += ' {' + clean[8:len(clean)-2] + '}'
                continue
        if clean.startswith('.'):
            newlines += ['<' + clean[:9] + '>:']
            clean = clean[10:]
        if clean.startswith('<'):
            if last_was_label:
                label_sub[clean[:len(clean)-1]] = last_label
            else:
                newlines += [clean]
                last_was_label = True
                last_label = clean[:len(clean)-1]
        else:
            newlines += [clean + added_to_next_statement]
            added_to_next_statement = ''
            last_was_label = False
    for clean in newlines:    
        if clean.endswith('>:'):
            newlabel = clean[0:len(clean)-1]
            if label is not None and may_carry_on(ilist[label]):
                old_address = ilist[label][len(ilist[label])-1]['address']
                new_address = '0x%08x:' % (int(old_address[2:10], 16) + 4)
                instruction = create_instruction(['buwc',newlabel], new_address, label_sub)
                ilist = add_instruction(ilist, label, instruction)
            label = newlabel 
            continue
        fields = clean.split()
        print(fields)
        if fields[0][9] in '048c' and fields[2].endswith(':'):
            half_instruction = create_instruction(fields[3:], fields[0], label_sub)
            continue
        if fields[0][9] in '26ae' and fields[2].endswith(':') and half_instruction is not None:
            other_half_instruction = create_instruction(fields[3:], '0x00000000', label_sub)
            instruction = combine_halfs(half_instruction, other_half_instruction)
            half_instruction = None
            ilist = add_instruction(ilist, label, instruction)
            continue
        if not fields[4].endswith(':'):
            print('bad line ', clean, fields[2], fields[4])
            continue
        instruction = create_instruction(fields[5:], fields[0], label_sub)
        ilist = add_instruction(ilist, label, instruction)
    return ilist

def remove_unneeded_labels(ilist):
    target_count = {'<XUD_LLD_IoLoop>': 1}
    target_src = {}
    for i in ilist:
        for k in ilist[i]:
            if k['mnemonic'] == 'buwc':
                j = k['targets'][0]
                target_src[j] = i
                if j not in target_count:
                    target_count[j] = 0
                continue
            for j in k['targets']:
                if j in target_count:
                    target_count[j] += 1
                else:
                    target_count[j] = 1
    print(target_count)
    print(target_src)
    for j in target_count:
        if target_count[j] == 0:
            src_block = target_src[j]
            concat_block = ilist.pop(j)
            src_list = ilist[src_block]
            ilist[src_block] = src_list[:len(src_list)-1] + concat_block
            for k in target_src:
                if target_src[k] == j:
                    target_src[k] = src_block
        
constraints = read_constraints()
ilist = read_binary(sys.argv[1])
remove_unneeded_labels(ilist)
#calc_bb_timings(ilist)
pretty_print_ilist(ilist)

starting_points = [('<Loop_BadPid>', 2, '{XUD_TokenRx_Pid}')]
explored_starting_points = []
all_paths = {}
while starting_points != []:
    new_starting_points = []
    for i in starting_points:
        if i in explored_starting_points:
            continue
        explored_starting_points += [i]
        paths = {}
        explore_depth_first(ilist, i[0], i[1], 0, 0, [], True, paths, 1)
        if i in all_paths:
            print('ERROR, overwriting ', i)
        all_paths[i] = paths
        for k in paths:
            label = k[0]
            inum = k[1]
            new_starting_points += [k]
    starting_points = new_starting_points

html_out = html.header()
    
html_out += '''
<p>
Below is the output of the analyser. Text between curly braces
<tt>{BLAH}</tt> indicates a labelled timing endpoint. It is labelled in the source
code with a label <tt>xta_ep_BLAH</tt>.
</p><p>
Text between angular braces <tt>&lt;BLAR&gt;</tt> indicates a label in the source
code. All duplicate labels have been removed so each block of code is
uniquely identified by one label only. All labels that were not referenced
have also been removed. 
</p><p>
If a timing endpoint is spotted that has not been labelled as such (using
<tt>xta_ep_BLAH</tt>) it is labelled as <tt>[label:linenumber]</tt>. These
endpoints must be fixed in the source code by labelling them as a timing
endpoint.
</p><p>
After all paths have been analysed, all paths are first printed for which
there is no constraint in the
<a href='constraints.txt'>constraints.txt</a> file. This may be because
the endpoint was not labelled, or because no constraint has been given.
There should not be any of those paths. After that, all contraints are listed
that were not found in the analysis; these are also errors. Finally,
all constraint paths are listed with the most constrained path first.
Clickng on the arrow opens up details.
</p>
'''

unconstrained_endpoints = 0
combos = 0
for i in sorted(all_paths):
    if i[2] is None:
        unconstrained_endpoints += 1
    combos += len(all_paths[i])
        
if unconstrained_endpoints > 0:
    html_out += '<p><b>ERROR</b>: there are ' + str(unconstrained_endpoints) + ' unlabelled timing endpoints:</p>\n<ol>\n'
    for i in sorted(all_paths):
        if i[2] is None:
            html_out += '<li><tt>[' + i[0].replace('<','').replace('>','') + ':' + str(i[1]) + ']</tt></li>\n'
    html_out += '</ol>\n'

html_out += '<p>Found ' + str(combos) + ' paths between timing endpoints.</p>'
constrained_paths = []
c_out = ''
for i in sorted(all_paths):
    (constrained_paths,c_out) = pretty_print_paths(i, all_paths[i], constraints, constrained_paths, c_out)

if c_out != '':
    html_out += '<p><b>ERROR</b>: there are unconstrained paths (they may be caused by unlabelled timing endpoints):</p><ol>\n' + c_out + '</ol>\n'

if constraints != {}:
    html_out += '<p><b>ERROR</b>: unused constraints. These may be because there is a IN/OUT on the way that should be marked ``xta_no_pauseN:``</p><ol>\n'
    for i in constraints:
        html_out += '<li>' + i[0] + ' &#8658; ' + i[1] + ':' + str(constraints[i]) + 'ns</li>'
    html_out += '</ol>\n'
    
html_out += '\n<p><b>Constrained paths in order of severity.</b> Minimum device clock frequency is computed assuming 8 threads are running. If set to PRIORITY, these numbers can be mulitplied by 0.625 (5/8).</p>'
for i in sorted(constrained_paths, reverse=True):
    p = ''
    for l in i[2]:
        pre_text = 'ibuffer-fullness <LABEL>: alignment   instructions               cycle-count \n'
        separator = ''
        summary = '&nbsp;%d&nbsp;cycles:&nbsp;' % l['cycles']
        old_lab = ''
        for (lab,inum,cycle,ibuffer_fullness,alignment) in l['path']:
            if inum == 0:
                summary += separator + '<tt>&nbsp;' + lab.replace('<', '').replace('>','') + '&nbsp;</tt>'
                separator = " &#8658; "
                old_lab = lab
                pre_text += '  %s: 0xXXX%x\n' % (lab, alignment)
            pre_text += '%d     %-60s %2d\n' % (ibuffer_fullness, ilist[lab][inum]['args'].strip(), cycle)
        pre_text = html.pre(pre_text)
        p +=  html.openable_element(summary, pre_text)
    html_out += html.openable_element('    %6.0f MHz: required for %s' % (i[0], i[1]), p)
html_out += html.trailer()
with open('xud_xta.html','w') as fd:
    fd.write(html_out)
