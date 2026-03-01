using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Updater1
{
    static class P_Updater
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        /// 

        static Mutex mutex;
        static bool ctrl;

        [STAThread]
        static void Main()
        {
            mutex = new Mutex(true, "P_Updater", out ctrl);
            if (ctrl)
            {
                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                Application.Run(new FormUpdateMain());
            }
            else
                Environment.Exit(0);
        }
    }
}
