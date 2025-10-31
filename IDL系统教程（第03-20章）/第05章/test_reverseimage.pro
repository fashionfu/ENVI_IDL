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
;ѭ���������ؽ���
FUNCTION DO_METHOD_01, img
  ;��ѭ��
  FOR i=0,2047 DO BEGIN
    ;ͼ����һ����ѭ��
    FOR j=0,1023  DO BEGIN
      ;���浱ǰ������
      tmp = img[i,j]
      ;���м�ԳƵ��滻
      img[i,j]= img[i,2047-j]
      ;��������
      img[i,2047-j] = tmp
    ENDFOR
  ENDFOR
  ;���ط�ת���
  RETURN, img
END
;����IDL�ص��н���
FUNCTION DO_METHOD_02, img
  ;ͼ����һ����ѭ��
  FOR j=0,1023  DO BEGIN
    ;���浱ǰ������
    tmp = img[*,j]
    ;���м�ԳƵ��滻
    img[*,j]= img[*,2047-j]
    ;��������
    img[*,2047-j] = tmp
  ENDFOR
  ;���ط�ת���
  RETURN, img
END
;��ռ��һ���ڴ棬������Ӽ��
;
FUNCTION DO_METHOD_03, img
  ;���ݸ���һ��
  img2 = img
  ;ͼ����ֵ
  FOR j=0,2047 DO img2=img[*,2047-j]
  ;���ط�ת���
  RETURN, img2
END
;��ռ��һ���ڴ�,��һ���Ż�
;
FUNCTION DO_METHOD_04, img

  ;����IDL���Խ�ͼ����ֵ
  img2 = img[*,2047-INDGEN(2048)]
  ;���ط�ת���
  RETURN, img2
END
;��ѷ���-IDL�Դ�����ʵ��
;
FUNCTION DO_METHOD_05, img
  img = ROTATE(img,7)
  RETURN, img
END
PRO TEST_REVERSEIMAGE
  PROFILER, /SYSTEM
  ;��������2048*2048
  img = FLTARR(2048,2048)
  ;��¼��ʼʱ��
  starttime = SYSTIME(1)
  ;��תͼ��
  img = DO_METHOD_01(img)
  ;�������ʱ��
  PRINT,'Method01:',SYSTIME(1) - starttime
  ;
  ;��¼��ʼʱ��
  starttime = SYSTIME(1)
  ;��תͼ��
  img = DO_METHOD_02(img)
  ;�������ʱ��
  PRINT,'Method02:',SYSTIME(1) - starttime
  
  ;��¼��ʼʱ��
  starttime = SYSTIME(1)
  ;��תͼ��
  img = DO_METHOD_03(img)
  ;�������ʱ��
  PRINT,'Method03:',SYSTIME(1) - starttime
  
  ;��¼��ʼʱ��
  starttime = SYSTIME(1)
  ;��תͼ��
  img = DO_METHOD_04(img)
  ;�������ʱ��
  PRINT,'Method04:',SYSTIME(1) - starttime
  
  ;��¼��ʼʱ��
  starttime = SYSTIME(1)
  ;��תͼ��
  img = DO_METHOD_05(img)
  ;�������ʱ��
  PRINT,'Method05:',SYSTIME(1) - starttime
  
END
;Method01:       1.1450000
;Method02:     0.023999929
;Method03:     0.020999908
;Method04:     0.031000137
;Method05:     0.016000032