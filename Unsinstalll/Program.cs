using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Unsinstalll
{
    static class Program
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        /// 

        public static bool IsRemove = false;
        [STAThread]
        static void Main(string[] arg)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            if(arg.Length>0)
                if (arg[0] == "DelVal")
                    IsRemove = true;
            Application.Run(new Form1Uninstall());
        }
    }
}
