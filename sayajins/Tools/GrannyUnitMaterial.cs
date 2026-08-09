using System;
using System.IO;
using Firaxis.Framework;
using Firaxis.Framework.Granny;

internal static class GrannyUnitMaterial
{
    [STAThread]
    private static int Main(string[] args)
    {
        if (args.Length != 4)
        {
            Console.Error.WriteLine("Usage: GrannyUnitMaterial <input.gr2> <output.gr2> <template.gr2> <texture.dds>");
            return 2;
        }

        try
        {
            string input = Path.GetFullPath(args[0]);
            string output = Path.GetFullPath(args[1]);
            string template = Path.GetFullPath(args[2]);
            string texture = Path.GetFileName(args[3]);
            Directory.SetCurrentDirectory(AppDomain.CurrentDomain.BaseDirectory);
            Context.Add(new VirtualSpace());
            var context = new GrannyContext();
            IGrannyFile target = context.LoadGrannyFile(input);
            IGrannyMaterial unitMaterial = null;
            foreach (IGrannyMaterial material in target.Materials)
            {
                if (material.ShaderSet == "UnitShader_Skinned")
                {
                    unitMaterial = material;
                    break;
                }
            }
            if (unitMaterial == null)
            {
                IGrannyFile materials = context.LoadGrannyFile(template);
                foreach (IGrannyMaterial material in materials.Materials)
                {
                    if (material.ShaderSet == "UnitShader_Skinned")
                    {
                        unitMaterial = material;
                        break;
                    }
                }
                if (unitMaterial == null)
                    throw new InvalidOperationException("UnitShader_Skinned is missing from the model and template.");
                target.AddMaterialReference(unitMaterial);
            }

            unitMaterial.Name = "SayajinUnitMaterial";
            var textures = unitMaterial.FindParameterSet("UnitShaderTextures");
            textures.SetParameterValue("BaseTextureMap", texture);
            // Use the stock infantry specular map. It is guaranteed to be in
            // Civ V's unit VFS, unlike the editor-only black SREF placeholder.
            textures.SetParameterValue("SREFMap", "Infantry_SREF.dds");
            foreach (IGrannyMesh mesh in target.Meshes)
            {
                while (mesh.MaterialBindings.Count > 0)
                    mesh.RemoveMaterialBinding(mesh.MaterialBindings[0]);
                mesh.MaterialBindings.Clear();
                mesh.AddMaterialBinding(unitMaterial);
            }

            string staging = output + ".staging.gr2";
            if (File.Exists(staging))
                File.Delete(staging);
            target.Filename = staging;
            target.Source = "Tool";
            target.Save();
            if (File.Exists(output))
                File.Delete(output);
            File.Move(staging, output);

            IGrannyFile check = context.LoadGrannyFile(output);
            if (check.Materials.Count != 1 || check.Meshes.Count == 0 || check.Meshes[0].MaterialBindings.Count != 1)
                throw new InvalidOperationException("The saved GR2 did not retain its unit material binding.");
            Console.WriteLine(
                "GR2_MATERIAL_OK file={0} meshes={1} materials={2} shader={3} texture={4}",
                Path.GetFileName(output), check.Meshes.Count, check.Materials.Count,
                check.Materials[0].ShaderSet, texture);
            return 0;
        }
        catch (Exception error)
        {
            Console.Error.WriteLine(error.ToString());
            return 1;
        }
    }
}
