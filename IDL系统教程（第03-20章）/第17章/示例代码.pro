;+
;  ��IDL������ơ�
;   -���ݿ��ӻ���ENVI���ο���
;        
; ʾ������
;
; ����: ������
;
; ��ϵ��ʽ��sdlcdyq@sina.com
;-


;��ʼ��Java�࣬��java���봴��5*5������
joArr = OBJ_NEW('IDLJavaObject$arrayDemo', 'arrayDemo',5,5)
;��ȡ�����±�Ϊ[2,3]��ֵ
PRINT, '����[2,3]=', joArr->GETVALUEBYINDEX(2,3)
;��ȡJava�����������ֵ
IDL_Arr = joArr->GETARRAYVALUES()
;�鿴��Java���л�ȡ�������Ϣ
HELP, IDL_Arr
;�鿴����
PRINT, '����[2,3]=', IDL_Arr[2,3]
;�������㣬ԭ����2��
IDL_Arr = IDL_Arr*2
;�����������洢��Java��
joArr->SETARRAYVALUE, IDL_Arr
;��ȡ�����±�Ϊ[2,3]��ֵ
PRINT, '����[2,3]=', joArr->GETVALUEBYINDEX(2,3)
;���ٶ���
OBJ_DESTROY, joArr


;��̬���ļ�����·��
dll = 'd:\imageProcess.dll'
;����ͼ��
image = BYTSCL(DIST(200, 200))
;����400*200�Ĵ���
WINDOW,1,xsize = 400,ysize =200
;��ʾԭʼͼ��ͼ18-2��ͼ��
TV,image,0
;�������
width = 200L
height = 200L
min = 20L
max = 220L
ret = CALL_EXTERNAL(dll, 'ImgExtend', image, width, height, min, max)
;��ʾDLL�����ͼ��ͼ18-2��ͼ��
TV, image,1


END