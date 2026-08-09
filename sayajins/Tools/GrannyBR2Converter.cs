using System;
using System.IO;
using System.Reflection;
using System.Runtime.Serialization;
using Firaxis.Framework;
using Firaxis.Framework.Granny;

internal static class GrannyBR2Converter
{
    [STAThread]
    private static int Main(string[] args)
    {
        if (args.Length != 3)
        {
            Console.Error.WriteLine("Usage: GrannyBR2Converter <template.gr2> <source.br2> <destination.gr2>");
            return 2;
        }

        try
        {
            string template = Path.GetFullPath(args[0]);
            string source = Path.GetFullPath(args[1]);
            string destination = Path.GetFullPath(args[2]);
            Directory.SetCurrentDirectory(AppDomain.CurrentDomain.BaseDirectory);
            Directory.CreateDirectory(Path.GetDirectoryName(destination));
            File.Copy(template, destination, true);
            Context.Add(new VirtualSpace());
            var context = new GrannyContext();
            Context.Add(context);
            IGrannyFile file = context.LoadGrannyFile(destination);
            Assembly nexusBuddy = Assembly.LoadFrom(Path.Combine(
                AppDomain.CurrentDomain.BaseDirectory, "NexusBuddy2.exe"));
            Type formType = nexusBuddy.GetType("NexusBuddy.NexusBuddyApplicationForm", true);
            object form = FormatterServices.GetUninitializedObject(formType);
            SetField(formType, form, "useLeaderTemplateRadioButton",
                Activator.CreateInstance(GetField(formType, "useLeaderTemplateRadioButton").FieldType));
            SetField(formType, form, "useSceneTemplateRadioButton",
                Activator.CreateInstance(GetField(formType, "useSceneTemplateRadioButton").FieldType));
            SetField(formType, form, "TempFiles", new System.Collections.Generic.List<string>());
            SetField(formType, form, "rand", new Random(5105));

            string modelTemplate = Path.Combine(
                AppDomain.CurrentDomain.BaseDirectory, "NexusBuddyModelTemplate.gr2");
            using (Stream input = nexusBuddy.GetManifestResourceStream(
                "NexusBuddy.GrannyTemplates.model_template.gr2"))
            using (FileStream output = File.Create(modelTemplate))
            {
                if (input == null)
                    throw new InvalidDataException("Nexus Buddy model template resource was not found");
                input.CopyTo(output);
            }
            SetField(formType, form, "modelTemplateFilename", modelTemplate);
            SetField(formType, form, "leaderTemplateFilename", modelTemplate);
            SetField(formType, form, "sceneTemplateFilename", modelTemplate);
            FieldInfo globalForm = formType.GetField(
                "form", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static);
            globalForm.SetValue(null, form);
            Type importerType = nexusBuddy.GetType("NexusBuddy.FileOps.BR2Importer", true);
            object importer = Activator.CreateInstance(importerType);
            MethodInfo import = null;
            foreach (MethodInfo candidate in importerType.GetMethods(
                BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Static))
            {
                if (candidate.Name == "overwriteMeshes")
                {
                    import = candidate;
                    break;
                }
            }
            if (import == null)
                throw new MissingMethodException(importerType.FullName, "overwriteMeshes");
            try
            {
                import.Invoke(importer, new object[] { file, source, context, 0 });
            }
            catch (TargetInvocationException error)
            {
                // The headless converter intentionally has no Nexus Buddy UI.
                // overwriteMeshes performs all data replacement before its final
                // UI save/status call, so only that specific tail failure is safe
                // to replace with IGrannyFile.Save below.
                string trace = error.InnerException == null ? "" : error.InnerException.StackTrace;
                if (trace == null || trace.IndexOf("saveAsAction", StringComparison.Ordinal) < 0)
                    throw;
            }
            if (file.Materials.Count > 0)
            {
                foreach (IGrannyMesh mesh in file.Meshes)
                {
                    if (mesh.MaterialBindings.Count == 0)
                        mesh.AddMaterialBinding(file.Materials[0]);
                }
            }
            if (!file.Save())
                throw new IOException("Granny API could not save " + destination);
            if (!File.Exists(destination))
                throw new IOException("Nexus Buddy did not create " + destination);
            Console.WriteLine("BR2_GR2_OK source={0} output={1} bytes={2}",
                Path.GetFileName(source), Path.GetFileName(destination), new FileInfo(destination).Length);
            return 0;
        }
        catch (Exception error)
        {
            Console.Error.WriteLine(error.ToString());
            return 1;
        }
    }

    private static FieldInfo GetField(Type type, string name)
    {
        FieldInfo field = type.GetField(
            name, BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Static);
        if (field == null)
            throw new MissingFieldException(type.FullName, name);
        return field;
    }

    private static void SetField(Type type, object target, string name, object value)
    {
        GetField(type, name).SetValue(target, value);
    }
}
