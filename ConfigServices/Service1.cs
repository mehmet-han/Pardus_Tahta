using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.ServiceProcess;
using System.Text;
using System.Timers;

namespace ConfigServices
{
    public partial class SmartBoardService : ServiceBase
    {
        public SmartBoardService()
        {
            InitializeComponent();
        }
        string ProgramFls(int which)
        {
            switch (which)
            {
                case 1: //veritabanı
                    return "C:\\Windws";
                case 2: //FatihProjesi,_usb
                    return "C:\\pf";
                case 3://configure
                    return "C:\\Configure";
                default:
                    return "C:\\pf";
            }
        }


        Timer timer = new Timer();
        protected override void OnStart(string[] args)
        {
            loadok = false;
            bo1 = false; 
            bo2 = false;
            say = 0;
            timer.Elapsed += new ElapsedEventHandler(OnElapsedTime);
            timer.Interval = 1000;
            timer.Enabled = true;
        }
        void LogSave(string logname)
        {
            return;
            if (logname.Trim() == "")
                return;
            try
            {
                string fileName = @"C:\Logs\lgs.txt";
                if (!Directory.Exists(@"C:\Logs"))
                    Directory.CreateDirectory(@"C:\Logs");
                if(File.Exists(fileName))
                {
                    FileInfo fi = new FileInfo(fileName);
                    if (fi.Length > 525824)
                    {
                        File.Delete(fileName);
                    }
                }
                FileStream fs = new FileStream(fileName, FileMode.OpenOrCreate, FileAccess.Write);
                fs.Close();
                File.AppendAllText(fileName, Environment.NewLine + logname);
            }
            catch {; }

        }
        string Val = "";
        string Val1 = "";
        string Argumnt = "";
        int say = 0;
        bool bo1 = false, bo2 = false,loadok=false;
        private void OnElapsedTime(object source, ElapsedEventArgs e)
        {
            say++;
            try
            {
                if (loadok)
                {
                    string logName = "";
                    bo1 = false;
                    bo2 = false;
                    try
                    {
                        Process[] prs = Process.GetProcesses();
                        foreach (Process pr in prs)
                        {
                            if (pr.ProcessName == "FatihProjesi")
                            {
                                bo1 = true;
                                break;
                            }
                        }
                        switch (say)
                        {
                            case 3:
                                if (!bo1)
                                {
                                    if (File.Exists(ProgramFls(2) + "\\Systm\\FatihProjesi.exe"))
                                    {
                                        try
                                        {

                                            ApplicationLoader.CreateProcessAsUser(ProgramFls(2) + "\\Systm\\FatihProjesi.exe", "start");
                                        }
                                        catch (Exception ex)
                                        {
                                            logName += ProgramFls(2) + "\\Systm\\FatihProjesi.exe => yolunada hata{" + ex.Message + "}" + "\n\n============================================================================================================================================================\n\n";
                                        }
                                    }
                                }
                                break;
                            case 7:

                                try
                                {
                                    Val = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run\\";
                                    Val1 = ProgramFls(2) + "\\Systm\\FatihProjesi.exe";
                                    Argumnt = "/C reg add " + Val + " /f /v FatihProjesi /t REG_SZ /d \"" + Val1 + "\"";
                                    ApplicationLoader.CreateProcessAsUser("C:\\Windows\\system32\\cmd.exe", Argumnt);
                                }
                                catch (Exception ex)
                                {
                                    logName += ex.Message + "\n\n============================================================================================================================================================\n\n";
                                }

                                break;
                            case 9:
                                try
                                {
                                    Val = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System";
                                    Argumnt = "/C reg add " + Val + " /f /v DisableTaskMgr /t REG_DWORD /d 1";
                                    ApplicationLoader.CreateProcessAsUser("C:\\Windows\\system32\\cmd.exe", Argumnt);
                                }
                                catch (Exception ex)
                                {
                                    logName += "DisaplaTaskMgr : " + ex.Message + "\n\n============================================================================================================================================================\n\n";
                                }
                                break;
                            case 10:
                                try
                                {
                                    Val = "HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon";
                                    Argumnt = "/C reg add " + Val + " /f /v AutoRestartShell /t REG_DWORD /d 0";
                                    ApplicationLoader.CreateProcessAsUser("C:\\Windows\\system32\\cmd.exe", Argumnt);
                                }
                                catch (Exception ex)
                                {
                                    logName += "AutoRestartShell : " + ex.Message + "\n\n============================================================================================================================================================\n\n";
                                }
                                break;
                            case 11:
                                try
                                {
                                    Val = "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System";
                                    Argumnt = "/C reg add " + Val + " / v EnableLUA / t REG_DWORD / d 0 / f";
                                    ApplicationLoader.CreateProcessAsUser("C:\\Windows\\system32\\cmd.exe", Argumnt);
                                }
                                catch (Exception ex)
                                {
                                    logName += "AutoRestartShell : " + ex.Message + "\n\n============================================================================================================================================================\n\n";
                                }
                                break;
                        }
                    }
                    catch (Exception Ex)
                    {
                        logName += "Genel HATA : " + Ex.Message + "\n\n============================================================================================================================================================\n\n";
                    }
                    if (say >= 12)
                        say = 0;
                    LogSave(logName);
                }
                else
                {
                    if (say == 15)
                    {
                        string val = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run\\";
                        string val1 = ProgramFls(2) + "\\Systm\\FatihProjesi.exe";
                        string argumnt = "/C reg add " + val + " /f /v FatihProjesi /t REG_SZ /d \"" + val1 + "\"";
                        if (File.Exists(ProgramFls(2) + "\\Systm\\FatihProjesi.exe"))
                        {
                            ApplicationLoader.CreateProcessAsUser(ProgramFls(2) + "\\Systm\\FatihProjesi.exe", "start");
                            System.Threading.Thread.Sleep(1000);
                        }
                        ApplicationLoader.CreateProcessAsUser("C:\\Windows\\system32\\cmd.exe", argumnt);
                        loadok = true;
                        say = 0;
                        Memory_Class.FlushMemory();
                    }
                }
            }
            catch
            {
                say = 0;
            }
        }
        protected override void OnStop()
        {
        }
    }
}
