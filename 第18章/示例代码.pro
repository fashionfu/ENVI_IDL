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

  ;ѡ��ϵͳ�Դ���һ��sav�ļ���������������
  savefile = FILEPATH('cduskcD1400.sav', $
   SUBDIRECTORY=['examples', 'data'])
  ;����Savefile����
  sObj = OBJ_NEW('IDL_Savefile', savefile)
  ;���ö��󷽷���ѯsav�ļ�����
  sContents = sObj.CONTENTS()
  ;�鿴sav���ݸ���
  PRINT, sContents.N_VAR
 
  ;��ȡsav�ļ��еı�������
  sNames = sObj.NAMES()
  ;�鿴��������
  PRINT, sNames

  ;��ѯ����'density'����Ϣ����ͬ��size()����
  sDensitySize = sObj.SIZE('density')
  ;�鿴������Ϣ
  PRINT, sDensitySize

  ;�ָ�������IDL�ڴ���
  sObj.RESTORE, 'density'
  ;����iTools������ʾ��ͼ18.7��
  IVOLUME, density

end