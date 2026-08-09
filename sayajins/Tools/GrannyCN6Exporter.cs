using System;
using System.IO;
using System.Reflection;
using System.Runtime.Serialization;
using System.Windows.Forms;
using Firaxis.Framework;
using Firaxis.Framework.Granny;

internal static class GrannyCN6Exporter
{
    [STAThread]
    private static int Main(string[] args)
    {
        if (args.Length != 1)
        {
            Console.Error.WriteLine("Usage: GrannyCN6Exporter <model.gr2>");
            return 2;
        }
        try
        {
            string source = Path.GetFullPath(args[0]);
            Directory.SetCurrentDirectory(AppDomain.CurrentDomain.BaseDirectory);
            Context.Add(new VirtualSpace());
            var context = new GrannyContext();
            Context.Add(context);
            IGrannyFile file = context.LoadGrannyFile(source);
            Assembly nexusBuddy = Assembly.LoadFrom(Path.Combine(
                AppDomain.CurrentDomain.BaseDirectory, "NexusBuddy2.exe"));
            Type formType = nexusBuddy.GetType("NexusBuddy.NexusBuddyApplicationForm", true);
            object form = FormatterServices.GetUninitializedObject(formType);
            var materialList = new ListView();
            MethodInfo getIndieMaterial = formType.GetMethod(
                "GetIndieMaterialFromMaterial",
                BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static);
            if (getIndieMaterial == null)
                throw new MissingMethodException(formType.FullName, "GetIndieMaterialFromMaterial");
            foreach (IGrannyMaterial material in file.Materials)
            {
                var item = new ListViewItem(material.Name);
                item.Tag = getIndieMaterial.Invoke(null, new object[] { material });
                materialList.Items.Add(item);
            }
            SetField(formType, form, "materialList", materialList);
            FieldInfo globalForm = formType.GetField(
                "form", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static);
            globalForm.SetValue(null, form);
            Type exporterType = nexusBuddy.GetType("NexusBuddy.FileOps.CN6FileOps", true);
            MethodInfo export = exporterType.GetMethod(
                "cn6Export", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static);
            object result = export.Invoke(null, new object[] { file, 0, false });
            Console.WriteLine("CN6_EXPORT_OK source={0} result={1}",
                Path.GetFileName(source), result == null ? "<null>" : result.ToString());
            return 0;
        }
        catch (Exception error)
        {
            Console.Error.WriteLine(error.ToString());
            return 1;
        }
    }

    private static void SetField(Type type, object target, string name, object value)
    {
        FieldInfo field = type.GetField(
            name, BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Static);
        if (field == null)
            throw new MissingFieldException(type.FullName, name);
        field.SetValue(target, value);
    }
}
