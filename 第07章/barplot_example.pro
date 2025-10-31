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
;����ͼ���ƺ���
PRO EX_BOX, X0, Y0, X1, Y1, color
  ;����PolyFill���л���
  POLYFILL, [X0, X0, X1, X1], [Y0, Y1, Y1, Y0], COL = color
END
;
;����ͼ����Demo
;
PRO BARPLOT_EXAMPLE
  ;�������
  SOCKEYE=[463, 459, 437, 433, 431, 433, 431, 428, 430, 431, 430]
  COHO=[468, 461, 431, 430, 427, 425, 423, 420, 418, 421, 420]
  CHINOOK=[514, 509, 495, 497, 497, 494, 493, 491, 492, 493, 493]
  HUMPBACK=[467, 465, 449, 446, 445, 444, 443, 443, 443, 443, 445]
  names = ['Coho','Sockeye','Humpback','Chinook']
  ALLPTS = [[COHO], [SOCKEYE], [HUMPBACK], [CHINOOK]]
  ;���
  YEAR = [1967, 1970, INDGEN(9) + 1975]
  XVAL = FINDGEN(4)/5. + .2
  ;��һ���������
  YVAL = [COHO[0], SOCKEYE[0], HUMPBACK[0], CHINOOK[0]]
  ;���������ݵ����ߣ�x��Χ[0,1],xVal������ʾ.
  window,xsize = 600,ysize = 400
  ;���ڱ���names��ʾ�߱���:
  PLOT, XVAL, YVAL, /YNOZERO, XRANGE = [0,1], XTICKV = XVAL, $
    XTICKS = 3, XTICKNAME = NAMES, /NODATA, $
    TITLE = 'Salmon Populations, 1967'
  ;������״ͼ���ڿ̶����м���ʾ��!Y.CRange��X��̶��ߵ�y��ʶ��
  FOR I = 0, 3 DO EX_BOX, XVAL[I] - .08, !Y.CRANGE[0], $
    XVAL[I] + 0.08, YVAL[I], 128
END

