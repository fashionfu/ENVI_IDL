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
 
 file = dialog_pickfile(/Directory)
 ;�Ի���ѡ���ļ�����ͼ11.16-(b).
 file = dialog_pickfile()
 ;��ӳ�ʼ��·�����ļ����͹��ˣ���ͼ11.16-(c).
 file = dialog_pickfile(title ='ѡ���ļ�', path ='c:\', get_path = oriPath, filter ='*.pro')
 ;�ļ����ˣ������Զ�ѡ����ͼ11.16-(d).
 file = dialog_pickfile(title ='ѡ���ļ�', path =oriPath, /multiple_files, $ 
   filter =[['*.jpg','*.bmp','*.tif','*.*'], ['JPG�ļ�','BMP�ļ�','TIF�ļ�','�����ļ�']])
   
    ;��Ϣ��ʾ�Ի��򣬼�ͼ11.17-(a).
 rlt= DIALOG_MESSAGE('��Ϣ��ʾ',title='��Ϣ',/Information)
 ;������ʾ�Ի��򣬼�ͼ11.17-(b).
 rlt= DIALOG_MESSAGE('��������ˣ�',title='����',/Error)
 ;���ʶԻ��򣬼�ͼ11.17-(c).
 rlt= DIALOG_MESSAGE('��ȷô��',title='����',/Question)
 ;���ʶԻ��򣬼�ͼ11.17-(d).
rlt= DIALOG_MESSAGE('����?',title='����',/Cancel)
   
   
 END