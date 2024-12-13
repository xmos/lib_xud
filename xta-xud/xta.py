from instr_db import uses_memory, is_io, may_go_on
import subprocess
import sys

def create_instruction(fields, alignment, label_sub):
    global uses_memory, is_io, may_go_on
    mnemonic = fields[0]
    targets = []
    xta_endpoints = []
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
        if i.startswith('{'):
            xta_endpoints += [i]
    instr = {
             'cycles': 0,
             'buf_before': 0,
             'memory' : uses_memory[mnemonic],
             'io' : is_io[mnemonic] and not 'NOPAUSE' in fields,
             'may_go_on': may_go_on[mnemonic],
             'mnemonic' : mnemonic,
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
            instrs = instrs[0:j] + [create_instruction(['fnop'],0,{})] + instrs[j:]
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

def explore_depth_first(ilist, label, inum, cycle_count, depth, path, start, paths):
    if depth > 10:
        register_new_path(paths, cycle_count, depth, label, inum, None, 'Fail', path)
        return
    instrs = ilist[label]
    while inum < len(instrs):
        cycle_count += 1
        if instrs[inum]['io'] and not start:
            endpoint = None
            if instrs[inum]['xta_endpoints'] != []:
                endpoint = instrs[inum]['xta_endpoints'][0]
            register_new_path(paths, cycle_count, depth, label, inum, endpoint, instrs[inum]['mnemonic'], path)
            return
        for i in instrs[inum]['targets']:
                explore_depth_first(ilist, i, 0, cycle_count, depth+1, path + [{label : inum}], False, paths)
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
        
def pretty_print_paths(n, paths, constraints, constrained_paths, cnt):
    for p in paths:
        cycles = 0
        for pp in paths[p]:
            cycles = max(cycles, pp['cycles'])
        name = n
        if n[2] is not None:
            name = n[2]
        pame = p
        if p[2] is not None:
            pame = p[2]
        index = (name, pame)
        if index in constraints:
            ns = constraints.pop(index)
            constrained_paths += [((1000.0 / (ns/(8*cycles))),
                                  '%-30s => %-30s (%d cycles)' % (name,pame,cycles), paths[p])]
            continue
        print('   ', name, '=>', cycles, 'cycles to =>', pame)
        cnt += 1
        for pp in paths[p]:
            print('            ', pp['cycles'], pp['path'])
    return (constrained_paths, cnt)

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
                instruction = create_instruction(['buwc',newlabel], (alignment + 4) % 16, label_sub)
                ilist = add_instruction(ilist, label, instruction)
            label = newlabel 
            continue
        fields = clean.split()
        print(fields)
        if fields[0][9] in '048c' and fields[2].endswith(':'):
            alignment = int(fields[0][9], 16)
            half_instruction = create_instruction(fields[3:], alignment, label_sub)
            continue
        if fields[0][9] in '26ae' and fields[2].endswith(':') and half_instruction is not None:
            other_half_instruction = create_instruction(fields[3:], 1, label_sub)
            instruction = combine_halfs(half_instruction, other_half_instruction)
            half_instruction = None
            ilist = add_instruction(ilist, label, instruction)
            continue
        if not fields[4].endswith(':'):
            print('bad line ', clean, fields[2], fields[4])
            continue
        alignment = int(fields[0][9], 16)
        instruction = create_instruction(fields[5:], alignment, label_sub)
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
calc_bb_timings(ilist)
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
        explore_depth_first(ilist, i[0], i[1], 0, 0, [], True, paths)
        if i in all_paths:
            print('ERROR, overwriting ', i)
        all_paths[i] = paths
        for k in paths:
            label = k[0]
            inum = k[1]
            new_starting_points += [k]
    starting_points = new_starting_points
    
print('\nLabelled timing endpoints:')

for i in sorted(all_paths):
    if i[2] is not None:
        print('    ', i[2])
        
print('\nUnlabelled timing endpoints')
combos = 0
for i in sorted(all_paths):
    if i[2] is None:
        print('    ', i)
    combos += len(all_paths[i])

print('\nFound', combos ,'paths between timing endpoints.\nUnconstrained:')
constrained_paths = []
cnt = 0
for i in sorted(all_paths):
    (constrained_paths,cnt) = pretty_print_paths(i, all_paths[i], constraints, constrained_paths, cnt)
print('%d unconstrained paths found\n' % (cnt))

if constraints != {}:
    print('ERROR: unused constraints')
    for i in constraints:
        print('   ', i, constraints[i], 'ns')
    
print('\nConstrained assuming 8 threads running:')
for i in sorted(constrained_paths, reverse=True):
    print('    %6.0f MHz: required for %s' % (i[0], i[1]))

    
