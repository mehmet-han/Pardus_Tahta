using System;

namespace FatihProjesi
{
    class pctrl
    {
        public static string ps(DateTime dt, int a_m)
        {
            int Y = 0, d=0, m=0;
            try
            {
                Y = dt.Year;
                d = dt.Day;
                m = dt.Minute;

            if (m == 0 || m == 1)
                m = 2;
            m += a_m;
            return (Y * d * m * 85).ToString().Substring(0, 6);
            }
            catch {return "cukolmadi"; }
        }
        public static bool pc(string p, DateTime dt)
        {
            try
            {
                if (ps(dt, 0) == p)
                    return true;
                if (ps(dt, 1) == p)
                    return true;
                if (ps(dt, 2) == p)
                    return true;
                return false;
            }
            catch
            {
                return false;
            }
        }
    }
}
