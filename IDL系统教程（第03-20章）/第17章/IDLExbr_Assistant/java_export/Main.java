//���ð�
package helloworldex;
import com.idl.javaidl.*;
public class Main {
	//
	private static helloworldex test;
	
	public static void main(String[] args) {
		// TODO Auto-generated method stub
		// ���󴴽�
		test=new helloworldex();
		//��ʼ��
		test.createObject();
		//���ö��󷽷�
		JIDLString result =
			test.HELLOFROM(new JIDLString("IDL test"));
		//��������ַ���
		System.out.println(result);			
	}
}
