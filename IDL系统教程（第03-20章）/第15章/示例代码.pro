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
;����ģ���ź�����
N = 1024
delt = 0.02
u = -0.3 + 1.0 * SIN(2 * !PI * 2.8 * delt * FINDGEN(N)) $
  + 1.0 * SIN(2 * !PI * 6.25 * delt * FINDGEN(N)) $
  + 1.0 * SIN(2 * !PI * 11.0 * delt * FINDGEN(N))
  
;��ɢʱ������.
t = delt * FINDGEN(N)
;�źŲɼ���ʼʱ��
t1 = 1.0
;�źŲɼ�����ʱ��
t2 = 2.0
;�������ߣ�ͼ15.14��
IPLOT, T + delt/2, U, /HISTOGRAM, $
  XRANGE=[t1,t2], XTITLE='time in seconds', YTITLE='amplitude',$
  TITLE='Portion of Sampled Time Signal u(k)'
  
  
;���ٸ���Ҷ�任
V = FFT(U)
M = (INDGEN(N)-(N/2-1))
F = M / (N*delt)
;��ʾ�źŵ�ʵ����ͼ15.15�ϣ�
IPLOT, F, FLOAT(SHIFT(V,N/2-1)), $
  DIMENSIONS=[500,800], VIEW_GRID=[1,2], $
  YTITLE='Real part of spectrum', $
  XTITLE='Frequency in cycles / second', $
  XRANGE=[-1,1]/(2*delt), $
  TITLE='Real and Imaginary Spectrum of u(k)'
;��ʾ�źŵ��鲿��ͼ15.15�£�
IPLOT, F, IMAGINARY(SHIFT(V,N/2-1)), $
  /VIEW_NEXT, $
  YTITLE='Imaginary part of spectrum', $
  XTITLE='Frequency in cycles / second', $
  XRANGE=[-1,1]/(2*delt)
  
  
;���ٸ���Ҷ�任
V = FFT(U)
F = FINDGEN(N/2+1) / (N*delt)
;����
mag = ABS(V(0:N/2))
;��λ
phi = ATAN(V(0:N/2), /PHASE)
;���ȵĶ�����ʵ��ɫ����λ���ȣ���ɫ��
IPLOT, F, 20*ALOG10(mag),$
  YTITLE='Magnitude in dB / Phase in degrees', $
  XTITLE='Frequency in cycles / second', COLOR=[72,72,255], $
  TITLE='Magnitude (solid) and Phase (dashed)'
IPLOT, F, phi/!DTOR, $
  YRANGE=[-180,180],   YMAJOR=7, /X_LOG, $
  XRANGE=[1.0,1.0/(2.0*delt)], $
  LINESTYLE=2,  /OVERPLOT
  
  
;���ٸ���Ҷ�任
V = FFT(U)
F = FINDGEN(N/2+1) / (N*delt)
;���ƹ����ף�ͼ15.17��
IPLOT, F, ABS(V(0:N/2))^2, $
  YTITLE='Power Spectrum of u(k)', /Y_LOG, YMINOR=0, $
  XTITLE='Frequency in cycles / second', /X_LOG, $
  XRANGE=[1.0,1.0/(2.0*delt)], $
  TITLE='Power Spectrum'
  
;���������ź�����
N = 1024
delt = 0.02
T = delt * FINDGEN(N)
f1 = 5.0 / ((n-1)*delt)
f2 = 0.5 / ((n-1)*delt)
R = SIN(2*!PI*f1*T) * SIN(2*!PI*f2*T)
;����ϣ�����ر任��ͼ15.18��
IPLOT, T, R, -FLOAT(HILBERT(R)), $
  XTITLE = 'time in seconds', $
  YTITLE = 'real', ZTITLE = 'imaginary', $
  TITLE='Analytic Signal for r(t) Using Hilbert Transform'
  
  
  
;��������
delt = 0.02
;����f_low�Ĺ���
f_low = 15.
;����f_high�Ĺ���
f_high = 7.
;��������
a_ripple = 50.
;�˲�����
nterms = 40
;����������Ӧ
bs_ir_k = DIGITAL_FILTER(f_low*2*delt, f_high*2*delt, $
  a_ripple, nterms)
nfilt = N_ELEMENTS(bs_ir_k)
;�������ٸ���Ҷ��Ƶ����Ӧ
bs_fr_k = FFT(bs_ir_k) * nfilt
;�����˲����ķ���
f_filt = FINDGEN(nfilt/2+1) / (nfilt*delt)
mag = ABS(bs_fr_k(0:nfilt/2))
;�����˲������ͼ15.19��
IPLOT, f_filt, 20*ALOG10(mag), YTITLE='Magnitude in dB', $
  XRANGE=[1.0,1.0/(2.0*delt)], YRANGE=[-60,20], $
  XTITLE='Frequency in cycles / second', /X_LOG, $
  TITLE='Frequency Response for Bandstop FIR Filter (Kaiser)'
  
  
  
  
;ģ������ź�
delt = 0.02
f0 = 6.5
C = (1.0-!PI*f0*delt) / (1.0+!PI*f0*delt)
B = [(1+C^2)/2, -2*C, (1+C^2)/2]
A = [   C^2,    -2*C,     1    ]
na = N_ELEMENTS(A)-1
nb = N_ELEMENTS(B)-1
N = 1024L
U = FLTARR(N)
U[0] = FLOAT(N)
Y = FLTARR(N)
Y[0] = B[2]*U[0] / A[na]
;�ݹ�����˲��ź�
FOR K = 1, N-1 DO $
  Y(K) = ( TOTAL( B[nb-K>0:nb  ]*U[K-nb>0:K  ] ) $
  - TOTAL( A[na-K>0:na-1]*Y[K-na>0:K-1] ) ) / A[na]
;Ƶ�׼���.
V = FFT(Y)
F = FINDGEN(N/2+1) / (N*delt)
mag = ABS(V(0:N/2))
phi = ATAN(V(0:N/2), /PHASE)
;����������ʾ��ͼ15.20�ϣ�
IPLOT, F, 20*ALOG10(mag), DIMENSIONS=[550,800], $
  VIEW_GRID=[1,2], YTITLE='Magnitude in dB', $
  XTITLE='Frequency in cycles / second', $
  /X_LOG, XRANGE=[1.0,1.0/(2.0*delt)], $
  TITLE='Frequency Response Function of b(z)/a(z)'
;����������ʾ��ͼ15.20�£�
IPLOT, F, phi/!DTOR, $
  /VIEW_NEXT, YTITLE='Phase in degrees', $
  YRANGE=[-180,180], YTICKS=4, YMINOR=3, $
  XTITLE='Frequency in cycles / second', /X_LOG, $
  XRANGE=[1.0,1.0/(2.0*delt)]
  
END