# Development of a Stack-Framework

For some applications (especially recursive functions) the stack of the 6502 is too small, so that stack-overflows lead to a wrong behavior of some programs. The task of this project was to develop an own stack-framework that implements a larger stack (user defined size) with the methods JSR_, PHA_, PLA_, PHX_, PLX_, PHY_, PLY_, PHP_ and  PLP_  as macros. These commands should show the same behavior as the original commands (especially the effected flags should be the same).

Notes I made for the implementation:
- Use a real pointer for the new stack-pointer
- For implementing the JSR_ command you should check how to give parameters to macros
- In some cases local labels (visible only in the macro) could be needed. In this case add a point “.” in front of the specified label.
- Make sure that interrupts do not lead to inconsistencies
- Make sure that every command effects the flags in the way it is supposed to
- Allow to check for stack-overflows or stack-“underflows”
