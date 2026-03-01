using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Net;
using System.Net.NetworkInformation;
using System.Text;
using System.Threading;
using System.Windows.Forms;

namespace FatihProjesi
{
    class thslrss
    {
        public int tahtano;
        public string tahtaname;
    }
    class SmartBoardType
    {
        public int id;
        public string Name;
        public string[, ,] hours = new string[8, 19, 3];
    }
    class ClassClient
    {
        public static int shutDown = 0, TahtaLock = 0, SystemRemove = 0, LogSend = 0;
        public static string Message;
        public static string lname = "", vname = "";
        static void logRequest()
        {
            try
            {
                if (!NetworkInterface.GetIsNetworkAvailable())
                    return;
                using (var wb = new System.Net.WebClient())
                {
                    wb.Credentials = new NetworkCredential(ClassVariable.wbUser, ClassVariable.wbPass);
                    wb.Headers.Add("UserAgent", ClassVariable.userAgent);
                    wb.Headers.Add("User-Key", Tools.userKey());
                    wb.Headers.Add("UserCore", Tools.cFnc("5574"));
                    var data = new NameValueCollection();
                    data["corporate_code"] = ClassVariable.OPS.k;
                    data["fnc"] = "3480";
                    data["t_n"] = ClassVariable.OPS.t;
                    wb.UploadValues(ClassVariable.ApiUrl, "POST", data);
                }
            }
            catch
            {
                ;
            }
        }
        public static void save()
        {
            try
            {
                if (!NetworkInterface.GetIsNetworkAvailable())
                    return;
                if (vname == "logistek")
                    logRequest();
                using (var wb = new System.Net.WebClient())
                {
                    wb.Credentials = new NetworkCredential(ClassVariable.wbUser, ClassVariable.wbPass);
                    wb.Headers.Add("User-Agent", ClassVariable.userAgent);
                    wb.Headers.Add("User-Key", Tools.userKey());
                    wb.Headers.Add("UserCore", Tools.cFnc("5571"));
                    var data = new NameValueCollection();
                    data["corporate_code"] = ClassVariable.OPS.k;
                    data["fnc"] = "3480";
                    data["t_n"] = ClassVariable.OPS.t;
                    data["log"] = ClassVariable.Vercion + "-" + ClassVariable.SubVersiyon + ":" + lname;
                    data["vog"] = vname;
                    wb.UploadValues(ClassVariable.ApiUrl, "POST", data);
                }
            }
            catch
            {
                ;
            }
        }
        public static void LogSave(string LogName, string vn)
        {
            if (!NetworkInterface.GetIsNetworkAvailable())
                return;
            if (LogName == "")
                return;
            lname = LogName;
            vname = vn;
            Thread thread = new Thread(new ThreadStart(save));
            thread.Start();
        }
        internal static void NullVal(int a)
        {
            ClassClient.shutDown = a;
            ClassClient.TahtaLock = a;
            ClassClient.SystemRemove = a;
            ClassClient.LogSend = 0;
            ClassClient.Message = "";
        }
        public static void CtrlPost()
        {
            if(ClassVariable.OPS.k == "0"|| ClassVariable.OPS.t == "0")
            {
                NullVal(-1);
                return;
            }
            if(ClassVariable.IsFlash)
            {
                NullVal(-2);
                return;
            }
            if (!NetworkInterface.GetIsNetworkAvailable())
            {
                NullVal(-3);
                return;
            }
            if(!Form1.startWork)
            {
                NullVal(-4);
                return;
            }
            try
            {
                using (var wb = new System.Net.WebClient())
                {
                    wb.Headers.Add("User-Agent", ClassVariable.userAgent);
                    wb.Headers.Add("User-Key", Tools.userKey());
                    wb.Credentials = new NetworkCredential(ClassVariable.wbUser, ClassVariable.wbPass);
                    wb.Headers.Add("UserCore", Tools.cFnc("5567"));
                    var data = new NameValueCollection();
                    data["corporate_code"] = ClassVariable.OPS.k;
                    data["fnc"] = "3480";
                    data["t_n"] = ClassVariable.OPS.t;
                    data["t_na"] = ClassVariable.OPS.tn;
                    var response = wb.UploadValues(ClassVariable.ApiUrl, "POST", data);
                    string[] donut = Encoding.UTF8.GetString(response).Split(',');
                    if(Form1.startWork)
                    {
                        TahtaLock = Convert.ToInt32(donut[0]);
                        if (donut[1].ToString() != "0")
                            Message = donut[1];
                        shutDown = Convert.ToInt32(donut[2]);
                        SystemRemove = Convert.ToInt32(donut[3]);
                        if (donut.Length > 4)
                            LogSend = Convert.ToInt32(donut[4]);
                    }
                    else
                        NullVal(-4);
                }
            }
            catch
            {
                NullVal(-5);
               // LogSave(ex.Message, "CtrlPost");
            }
        }
        public static void SetValue(string colmn, string value)
        {
            if (!NetworkInterface.GetIsNetworkAvailable())
                return;
            int rs = 0;
        rpt:
            rs++;
            try
            {
                using (var wb = new System.Net.WebClient())
                {
                    wb.Headers.Add("User-Agent", ClassVariable.userAgent);
                    wb.Headers.Add("User-Key", Tools.userKey());
                    var data = new NameValueCollection();
                    wb.Credentials = new NetworkCredential(ClassVariable.wbUser, ClassVariable.wbPass);
                    wb.Headers.Add("UserCore", Tools.cFnc("5566"));
                    data["corporate_code"] = ClassVariable.OPS.k;
                    data["fnc"] = "3480";
                    data["c_l"] = colmn;
                    data["value"] = value;
                    data["t_n"] = ClassVariable.OPS.t;
                    wb.UploadValues(ClassVariable.ApiUrl, "POST", data);
                }
            }
            catch (Exception ex)
            {
                if (rs < 3)
                {
                    System.Threading.Thread.Sleep(500);
                    goto rpt;
                }
                LogSave(ex.Message, "SetValue");
            }
        }
        public static bool tg = false;
        public static List<thslrss> mylst = new List<thslrss>();
        public static void GetValues()
        {
            if (!NetworkInterface.GetIsNetworkAvailable())
                return;
            try
            {
                ClassVariable.IsSaveData = true;
                using (var wb = new System.Net.WebClient())
                {
                    var data = new NameValueCollection();
                    wb.Headers.Add("User-Agent", ClassVariable.userAgent);
                    wb.Headers.Add("User-Key", Tools.userKey());
                    wb.Credentials = new NetworkCredential(ClassVariable.wbUser, ClassVariable.wbPass); 
                    wb.Headers.Add("UserCore", Tools.cFnc("5563"));
                    data["corporate_code"] = ClassVariable.OPS.k;
                    data["fnc"] = "3480";
                    var response = wb.UploadValues(ClassVariable.ApiUrl, "POST", data);
                    SmartBoardType[] items = JsonConvert.DeserializeObject<SmartBoardType[]>(Encoding.UTF8.GetString(response));
                    mylst.Clear();
                    if (items != null)
                    {
                        for (int i = 0; i < items.Length; i++)
                        {
                            if (tg)
                            {
                                thslrss th = new thslrss();
                                th.tahtano = items[i].id;
                                th.tahtaname = items[i].Name;
                                mylst.Add(th);
                            }
                            else
                            {
                                if (items[i].id.ToString() == ClassVariable.OPS.t)
                                {
                                    for (int s = 1; s < 8; s++)
                                    {
                                        for (int k = 1; k < 19; k++)
                                        {
                                            ClassVariable.OPS.hours[s, k, 1] = items[i].hours[s, k, 1];
                                            ClassVariable.OPS.hours[s, k, 2] = items[i].hours[s, k, 2];
                                        }
                                    }
                                    break;
                                }
                            }
                        }
                    }
                }
                if (!tg)
                    CheckFolder.SaveData();
            }
            catch (Exception ex)
            {
               // LogSave(ex.Message, "GetValues");
            }
            tg = false;
            ClassVariable.IsSaveData = false;
        }
        public static int Mhg = 0, Mhs = 0;
        public static string GetInspc(int st, int gn)
        {
            if (!NetworkInterface.GetIsNetworkAvailable())
                return "";
            if (ClassVariable.OPS.k == "0")
                return "";
            try
            {
                using (var wb = new WebClient())
                {
                    var data = new NameValueCollection();
                    wb.Headers.Add("User-Agent", ClassVariable.userAgent);
                    wb.Headers.Add("User-Key", Tools.userKey());
                    wb.Credentials = new NetworkCredential(ClassVariable.wbUser, ClassVariable.wbPass);
                    wb.Headers.Add("UserCore", Tools.cFnc("5573"));
                    data["corporate_code"] = ClassVariable.OPS.k;
                    data["fnc"] = "3480";
                    data["t_n"] = ClassVariable.OPS.t;
                    data["s_t"] = st.ToString();
                    data["g_n"] = gn.ToString();
                    var response = wb.UploadValues(ClassVariable.ApiUrl, "POST", data);
                    string coz = Encoding.UTF8.GetString(response);
                    return coz;
                }
            }
            catch
            {
                return "";
            }
        }

        public static string vck()
        {
           string Nw = ClassVariable.Vercion;
            if (!NetworkInterface.GetIsNetworkAvailable())
                return Nw;
            try
            {
                using (var wb = new System.Net.WebClient())
                {
                    Random Rn = new Random();
                    wb.Headers.Add("User-Agent", ClassVariable.userAgent);
                    wb.Headers.Add("User-Key", Tools.userKey());
                    wb.Credentials = new NetworkCredential(ClassVariable.wbUser, ClassVariable.wbPass);
                    wb.Headers.Add("UserCore", Tools.cFnc("5570"));
                    var data = new NameValueCollection();
                    data["fnc"] = "3480";
                    var response = wb.UploadValues(ClassVariable.ApiUrl, "POST", data);
                    Nw = Encoding.UTF8.GetString(response).Trim();
                }
            }
            catch
            {
                Nw = ClassVariable.Vercion;
            }
            return Nw;
        }
    }
}
