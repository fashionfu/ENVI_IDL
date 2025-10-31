#include <stdio.h>
#include <math.h>
#include <string.h>
#include <stdlib.h>
#include "imageStretch.h"
#include "export.h"

//��ʼ������������
static IDL_MSG_DEF msg_arr[]=
{	
	{	"imageStretch_ERROR",					"%NError:%s."},
	{	"imageStretch_NOSTRINGARRAY",			"%Nstring arrays not allowed %s"}
};

IDL_MSG_BLOCK msg_block;

//IDL�ӿ�
int IDL_Load(VOID)
{
	
	if(!(msg_block = IDL_MessageDefineBlock("imageStretch",ARRLEN(msg_arr),
		msg_arr))) {
		return IDL_FALSE ;
	}
	// ����IDLtoC_scalarExamplesStartup()
	if(!IMAGESTETCH_Startup()) {
		IDL_MessageFromBlock(msg_block,imageStretch_ERROR,
			IDL_MSG_RET,"��ʼ������ʧ��!");
	}
	return IDL_TRUE;
	
}
