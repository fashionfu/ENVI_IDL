#ifndef IDL_C_H
#define IDL_C_H
#include "export.h"
/* ��Ϣ����......*/
#define imageStretch_ERROR 0
#define imageStretch_NOSTRINGARRAY -1

/*��*/
#define ARRLEN(arr) (sizeof(arr)/sizeof(arr[0])) 

extern IDL_MSG_BLOCK msg_block;

/*���彫C������ӵ�IDL�еĹ��ܺ��˳�*/
extern void IMAGESTETCH_exit_handler(void);
extern int IMAGESTETCH_Startup(void);

#endif