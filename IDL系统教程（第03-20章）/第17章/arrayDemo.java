// arrayDemo:Java�࣬�������顢�������顢����ֵ����ͨ��IDL���á�
//
public class arrayDemo 
{
 //��������	
 short[][]  intarr;

 //���ݴ������ֵ��������
 public arrayDemo(int SIZE1,int SIZE2) {
   intarr = new short[SIZE1][SIZE2];
  //ѭ����ֵ������ֵ��������*2
   for (int i=0; i<SIZE1; i++) {
     for (int j=0; j<SIZE2; j++) {
    	 intarr[i][j] = (short)(i*2+j*2);
     }
   }
 }
 //setArrayValue����,�������鸳ֵ
 public void setArrayValue(short[][] _inArr) {
	 intarr = _inArr;
 }
 //��ȡ����ֵ
 public short[][] getArrayValues() {return intarr;}
 //����������ȡ����ֵ
 public short getValueByIndex(int i, int j) {
	return intarr[i][j];
 }
}



