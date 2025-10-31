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
;����ʾ���ݽ��аٷ�֮������������
;
PRo lineStrech2d,data;,min_index,max_index

  dimens=Size(data,/dimensions)
  if size(data,/N_DIMENSIONS) eq 2 then begin
      MinCount=float(dimens[0])*dimens[1]*0.02
      MaxCount=float(dimens[0])*dimens[1]*0.98
      ;���������Сֵ
      min=min(data,max=max)
      ;ͳ�����ݷֲ�
      hist=histogram(data)
      ;��ȡ�ۼӸ���
      hist_sum=total(hist,/cumulative)
      ; ������
      index=where(hist_sum GT MinCount)
      min_index=(float(index[0]+1)*(max-min)/256)+min
      ;������
      index=where(hist_sum GT MaxCount)
      max_index=(float(index[0]+1)*(max-min)/256)+min
      ;
      ;����
      data=Bytscl(temporary(data),min=min_index,max=max_index,top=255)

  endif
ENd