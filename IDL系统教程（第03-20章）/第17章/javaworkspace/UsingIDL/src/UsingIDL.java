import com.idl.javaidl.*;
public class UsingIDL {

	/**
	 * @param args
	 * @throws InterruptedException 
	 */
	public static void main(String[] args) throws InterruptedException {
		// TODO Auto-generated method stub
		
		//�½�JAVA_IDL_CONNECT���󲢳�ʼ��
		java_IDL_connect oJavaIDL;
		oJavaIDL = new java_IDL_connect();
		oJavaIDL.createObject();
			
		//JAVA_IDL_CONNECT���󷽷�����IDL����		
		oJavaIDL.executeString("data1 = SIN((FINDGEN(15)+1)/15*!PI/2)");
		oJavaIDL.executeString("bottom = data1+COS((FINDGEN(15))/15*!PI/2)");
		oJavaIDL.executeString("b = BARPLOT(data1, BOTTOM_VALUES=bottom, "+
		  "FILL_COLOR='red',BOTTOM_COLOR='yellow', C_RANGE=[0,1], /HORIZONTAL)");
		
		//�߳���ͣ5��
		Thread.currentThread().sleep(5000);
		
		//JAVA_IDL_CONNECT��������
		oJavaIDL.destroyObject();
		
	}

}
