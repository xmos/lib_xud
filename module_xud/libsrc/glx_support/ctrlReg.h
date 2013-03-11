#ifndef _CTRL_REG_H_
#define _CTRL_REG_H_

int WritePSCtrlReg(unsigned nod, unsigned processor, unsigned reg, unsigned data);
// Return success, value
{int, unsigned} ReadPSCtrlReg(unsigned nod, unsigned processor, unsigned reg);
int WriteSSCtrlReg(unsigned nod, unsigned reg, unsigned data);
// Return success, value
{int, unsigned} ReadSSCtrlReg(unsigned nod, unsigned reg);

#endif /* _CTRL_REG_H_ */
