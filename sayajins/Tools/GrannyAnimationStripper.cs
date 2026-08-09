using System;
using System.IO;
using Firaxis.Framework;
using Firaxis.Framework.Granny;

internal static class GrannyAnimationStripper
{
    [STAThread]
    private static int Main(string[] args)
    {
        if (args.Length != 2)
        {
            Console.Error.WriteLine("Usage: GrannyAnimationStripper <source.gr2> <destination.gr2>");
            return 2;
        }

        try
        {
            string sourceName = Path.GetFullPath(args[0]);
            string destinationName = Path.GetFullPath(args[1]);
            Directory.SetCurrentDirectory(AppDomain.CurrentDomain.BaseDirectory);
            Directory.CreateDirectory(Path.GetDirectoryName(destinationName));
            Context.Add(new VirtualSpace());
            var context = new GrannyContext();
            Context.Add(context);
            IGrannyFile source = context.LoadGrannyFile(sourceName);
            if (source.Animations.Count != 1)
                throw new InvalidDataException("Expected exactly one animation in " + sourceName);

            IGrannyFile destination = context.CreateEmptyGrannyFile(destinationName);
            destination.AddAnimationReference(source.Animations[0]);
            destination.AddArtToolAndExporterReference(source);
            if (!destination.Save())
                throw new IOException("Granny API could not save " + destinationName);

            Console.WriteLine("GR2_ANIMATION_ONLY_OK source={0} output={1} duration={2:F3}",
                Path.GetFileName(sourceName), Path.GetFileName(destinationName), source.Animations[0].Duration);
            return 0;
        }
        catch (Exception error)
        {
            Console.Error.WriteLine(error.ToString());
            return 1;
        }
    }
}
