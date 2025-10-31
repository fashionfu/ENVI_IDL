/*
 ;+
; ��IDL���Գ�����ơ�
; --���ݿ��ӻ���ENVI���ο���
;
; ʾ������
;
; ����: ������
;
; ��ϵ��ʽ��sdlcdyq@sina.com
;
;-
 */

using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
//ʹ��ע������
using Microsoft.Win32;
using System.IO;

namespace MixProgram
{
    public partial class Form1 : Form
    {
        //����������
        int xSpace = 0;
        int ySpace = 0;
        int y = 0;
        //��갴��״̬
        byte clickState = 0;

        public Form1()
        {
            InitializeComponent();
            //���ӹ��ֹ����¼�
            ((Control)this).MouseWheel += new MouseEventHandler(Form1_MouseWheel);
        }

        private void Form1_Load(object sender, EventArgs e)
        {
             
            //��ȡע����ȡIDL8.0��IDL7.1��IDL7.0��Ŀ¼
            RegistryKey rsg = null;

            rsg = Registry.LocalMachine.OpenSubKey("SOFTWARE\\ITT\\IDL\\8.2", true);

            if (rsg.GetValue("InstallDir") != null) //��ȡʧ�ܷ���null
            {
                //��ʼ��IDL80·��
                axIDLDrawWidget1.IdlPath = Path.Combine(rsg.GetValue("InstallDir").ToString(), @"IDL82\bin\bin.x86\idl.dll");
            }
            this.IDLDrawWidgetCreate();

        }

        private void IDLDrawWidgetCreate()
        {
            int n;
            //��ʼ��
            n = axIDLDrawWidget1.InitIDL((int)this.Handle);
            if (n == 0)
            {
                MessageBox.Show("IDL��ʼ��ʧ��", "IDL��ʼ��ʧ�ܣ��޷�������");
                return;
            }


            //���󷨳�����ʾ
            axIDLDrawWidget1.GraphicsLevel = 2;


            //����Դ���ļ�
            axIDLDrawWidget1.ExecuteStr(".compile 'imgprocess.pro'");
            axIDLDrawWidget1.ExecuteStr(".compile 'SetMapParamet__Define.pro'");
            axIDLDrawWidget1.ExecuteStr(".compile 'PROJECTIONSHOW__DEFINE.pro'");

            //�������ƫ����                
            this.xSpace = this.Width - axIDLDrawWidget1.Width;
            this.ySpace = this.Height - axIDLDrawWidget1.Height;
            //ָ���¼���C#��Ӧ
            axIDLDrawWidget1.RegisterForEvents(3);

            axIDLDrawWidget1.OnExpose = "if Obj_Valid(oProj) eq 1 then oProj.Draw";
            //
            //��ʼ������
            axIDLDrawWidget1.CreateDrawWidget();
        }

        private void Form1_ResizeEnd(object sender, EventArgs e)
        {
            axIDLDrawWidget1.Height = this.Height - this.ySpace;
            axIDLDrawWidget1.Width = this.Width - this.xSpace;
            //
            axIDLDrawWidget1.ExecuteStr("if Obj_Valid(oProj) eq 1 then oProj.ChangeDrawSize, " + axIDLDrawWidget1.Width + "," + axIDLDrawWidget1.Height);
            axIDLDrawWidget1.ExecuteStr("if Obj_Valid(oImg) eq 1 then oImg.ChangeDrawSize, " + axIDLDrawWidget1.Width + "," + axIDLDrawWidget1.Height);

        }
        //ͼ������ʾԭͼ
        private void buttonItem14_Click(object sender, EventArgs e)
        {
            axIDLDrawWidget1.ExecuteStr("if Obj_Valid(oImg) eq 0 then oImg = Obj_New('ImgShow'," + axIDLDrawWidget1.DrawId.ToString() + ")");     

        }
        //ͼ����-ƽ������
        private void process_ItemClick(object sender, EventArgs e)
        {
            axIDLDrawWidget1.ExecuteStr("if Obj_Valid(oImg) eq 1 then oImg.process,type = 'Smooth'");
        }
        //ͼ����-�߽���ȡ
        private void buttonItem1_Click(object sender, EventArgs e)
        {
            axIDLDrawWidget1.ExecuteStr("if Obj_Valid(oImg) eq 1 then oImg.process,type = 'CANNY'");
        }
        //ͶӰ�����ʼ��ʾ
        private void ribbonBar3_ItemClick(object sender, EventArgs e)
        {     
            axIDLDrawWidget1.ExecuteStr("if Obj_Valid(oProj) eq 0 then oProj = Obj_New('PROJECTIONShow'," + axIDLDrawWidget1.DrawId.ToString() + ") else oProj.oriShow");
        }
        //ͶӰ����ѡ��
        private void buttonItem5_Click(object sender, EventArgs e)
        {
            axIDLDrawWidget1.ExecuteStr("if Obj_Valid(oProj) eq 1 then oProj.SELECTMAPPROJECTION");
        }
        //��������ĵ���¼�����
        private void axIDLDrawWidget1_MouseDownEvent(object sender, AxIDLDRAWX3Lib._DIDLDrawX3Events_MouseDownEvent e)
        {
            y = axIDLDrawWidget1.Height - e.y;
            clickState = 1;
            axIDLDrawWidget1.ExecuteStr("if obj_Valid(oimg) EQ 1 then oImg.MousePress,"+ e.x.ToString() + "," + y.ToString());
            axIDLDrawWidget1.ExecuteStr("if obj_Valid(oProj)  EQ 1 then oProj.MousePress," + e.x.ToString() + "," + y.ToString());

        }
        //����������ƶ��¼�����
        private void axIDLDrawWidget1_MouseMoveEvent(object sender, AxIDLDRAWX3Lib._DIDLDrawX3Events_MouseMoveEvent e)
        {
            y = axIDLDrawWidget1.Height - e.y;            
            if (clickState == 1) axIDLDrawWidget1.ExecuteStr("if obj_Valid(oimg) then oImg.MouseMotion," + e.x.ToString() + "," + y.ToString());
            if (clickState == 1) axIDLDrawWidget1.ExecuteStr("if obj_Valid(oProj) then oProj.MouseMotion," + e.x.ToString() + "," + y.ToString());            
        }
        //��������ĵ����¼�����
        private void axIDLDrawWidget1_MouseUpEvent(object sender, AxIDLDRAWX3Lib._DIDLDrawX3Events_MouseUpEvent e)
        {
            axIDLDrawWidget1.ExecuteStr("if obj_Valid(oimg) then oImg.MouseRelease," + e.x.ToString() + "," + y.ToString());
            axIDLDrawWidget1.ExecuteStr("if obj_Valid(oProj) then oProj.MouseRelease," + e.x.ToString() + "," + y.ToString());
            clickState = 0;
        }
        //�������¼�
        void Form1_MouseWheel(object sender, MouseEventArgs e)
        {
            //
            y = axIDLDrawWidget1.Height - (e.Y - axIDLDrawWidget1.Location.Y);            
            axIDLDrawWidget1.ExecuteStr("if obj_Valid(oimg) then oImg.WheelEvents," + e.Delta.ToString() + ","
                + (e.X - axIDLDrawWidget1.Location.X).ToString() + "," + y.ToString());
            axIDLDrawWidget1.ExecuteStr("if obj_Valid(oProj) then oProj.WheelEvents," + e.Delta.ToString() + ","
                + (e.X - axIDLDrawWidget1.Location.X).ToString() + "," + y.ToString());
        }
        //�л�ͼ����ʾ
        private void ImageProcess_Click(object sender, EventArgs e)
        {           
        }
        //�л�ͶӰ��ʾ
        private void ribbonTabItem1_Click(object sender, EventArgs e)
        {
            //axIDLDrawWidget1.DestroyDrawWidget();
            //axIDLDrawWidget1.CreateDrawWidget();
            axIDLDrawWidget1.ExecuteStr("if Obj_Valid(oimg) then Obj_Destroy,oimg");
            axIDLDrawWidget1.ExecuteStr("if Obj_Valid(oProj) then Obj_Destroy,oProj");
            //axIDLDrawWidget1.ExecuteStr("oProj = Obj_New('PROJECTIONShow'," + axIDLDrawWidget1.DrawId.ToString() + ")");
        }
        
        private void Form1_FormClosed(object sender, FormClosedEventArgs e)
        {
            //
        }


        private void Form1_FormClosing_1(object sender, FormClosingEventArgs e)
        {
            e.Cancel =  MessageBox.Show("��ȷ��Ҫ�˳���", "����", MessageBoxButtons.YesNo, MessageBoxIcon.Exclamation) == DialogResult.No;
            // 
        }

        
    }
}