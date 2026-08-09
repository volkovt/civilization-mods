using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using Firaxis.Framework;
using Firaxis.Framework.Granny;

internal static class GrannyInspector
{
    [STAThread]
    private static int Main(string[] args)
    {
        if (args.Length == 0)
        {
            Console.Error.WriteLine("Usage: GrannyInspector <gr2 file or folder>");
            return 2;
        }

        try
        {
            string target = Path.GetFullPath(args[0]);
            bool details = args.Length > 1 && args[1] == "--details";
            bool runtime = args.Length > 1 && args[1] == "--runtime";
            Directory.SetCurrentDirectory(AppDomain.CurrentDomain.BaseDirectory);
            Context.Add(new VirtualSpace());
            var context = new GrannyContext();
            var files = new List<string>();
            if (Directory.Exists(target))
                files.AddRange(Directory.GetFiles(target, "*.gr2", SearchOption.TopDirectoryOnly));
            else
                files.Add(target);
            files.Sort(StringComparer.OrdinalIgnoreCase);

            foreach (string fileName in files)
            {
                IGrannyFile file = context.LoadGrannyFile(fileName);
                int bones = 0;
                if (file.Models.Count > 0 && file.Models[0].Skeleton != null)
                    bones = file.Models[0].Skeleton.Bones.Count;
                double duration = file.Animations.Count > 0 ? file.Animations[0].Duration : 0.0;
                var shaderSets = new List<string>();
                foreach (IGrannyMaterial material in file.Materials)
                    shaderSets.Add(material.ShaderSet ?? "<none>");

                Console.WriteLine(
                    "GR2_VALID file={0} models={1} meshes={2} materials={3} bones={4} animations={5} duration={6:F3} shaders={7}",
                    Path.GetFileName(fileName), file.Models.Count, file.Meshes.Count, file.Materials.Count,
                    bones, file.Animations.Count, duration, string.Join(",", shaderSets.ToArray()));

                foreach (IGrannyMesh mesh in file.Meshes)
                {
                    Console.WriteLine(
                        "GR2_MESH file={0} name={1} vertices={2} indices={3} materials={4} boneBindings={5}",
                        Path.GetFileName(fileName), mesh.Name, mesh.VertexCount, mesh.IndexCount,
                        mesh.MaterialBindings.Count, mesh.BoneBindings.Count);
                }
                if (runtime)
                {
                    DumpRuntimeObject("FILE", file);
                    foreach (IGrannyModel model in file.Models)
                        DumpRuntimeObject("MODEL", model);
                    foreach (IGrannyMesh mesh in file.Meshes)
                        DumpRuntimeObject("MESH", mesh);
                }
                if (details)
                {
                    for (int modelIndex = 0; modelIndex < file.Models.Count; modelIndex++)
                    {
                        IGrannyModel model = file.Models[modelIndex];
                        Console.WriteLine(
                            "GR2_MODEL file={0} index={1} name={2} placement={3}",
                            Path.GetFileName(fileName), modelIndex, model.Name,
                            FormatTransform(model.InitialPlacement));
                        if (model.Skeleton == null)
                            continue;
                        Console.WriteLine(
                            "GR2_SKELETON file={0} name={1} lodType={2} bones={3}",
                            Path.GetFileName(fileName), model.Skeleton.Name,
                            model.Skeleton.LODType, model.Skeleton.Bones.Count);
                        for (int boneIndex = 0; boneIndex < model.Skeleton.Bones.Count; boneIndex++)
                        {
                            IGrannyBone bone = model.Skeleton.Bones[boneIndex];
                            Console.WriteLine(
                                "GR2_BONE file={0} index={1} parent={2} name={3} transform={4}",
                                Path.GetFileName(fileName), boneIndex, bone.ParentIndex,
                                bone.Name, FormatTransform(bone.LocalTransform));
                        }
                    }
                    foreach (IGrannyAnimation animation in file.Animations)
                    {
                        Console.WriteLine(
                            "GR2_ANIMATION file={0} name={1} duration={2:F3} timestep={3:F6} trackGroups={4}",
                            Path.GetFileName(fileName), animation.Name, animation.Duration,
                            animation.TimeStep, animation.TrackGroups.Count);
                        foreach (IGrannyTrackGroup group in animation.TrackGroups)
                        {
                            var trackNames = new List<string>();
                            foreach (IGrannyTransformTrack track in group.TransformTracks)
                                trackNames.Add(track.Name);
                            Console.WriteLine(
                                "GR2_TRACK_GROUP file={0} name={1} tracks={2} values={3}",
                                Path.GetFileName(fileName), group.Name,
                                group.TransformTracks.Count, string.Join("|", trackNames.ToArray()));
                        }
                    }
                }
                foreach (IGrannyMaterial material in file.Materials)
                {
                    Console.WriteLine(
                        "GR2_MATERIAL file={0} name={1} shader={2} skinBones={3} alphaMode={4} zMode={5}",
                        Path.GetFileName(fileName), material.Name, material.ShaderSet,
                        material.SkinBoneCount, material.AlphaMode, material.ZMode);
                    for (int setIndex = 0; setIndex < material.GetParameterSetCount(); setIndex++)
                    {
                        IFGXParameterSet parameterSet = material.GetParameterSet(setIndex);
                        var values = new List<string>();
                        for (int valueIndex = 0; valueIndex < parameterSet.ParamCount; valueIndex++)
                        {
                            object value = parameterSet.GetParameterValue(valueIndex);
                            values.Add(value == null ? "<null>" : value.ToString());
                        }
                        Console.WriteLine(
                            "GR2_PARAMETERS file={0} block={1} active={2} count={3} values={4}",
                            Path.GetFileName(fileName), parameterSet.ParamBlock,
                            parameterSet.ParamActive, parameterSet.ParamCount,
                            string.Join("|", values.ToArray()));
                    }
                }
            }
            Console.WriteLine("GR2_VALIDATION_OK count={0}", files.Count);
            return 0;
        }
        catch (Exception error)
        {
            Console.Error.WriteLine(error.ToString());
            var reflectionError = error as System.Reflection.ReflectionTypeLoadException;
            if (reflectionError != null)
            {
                foreach (Exception loaderError in reflectionError.LoaderExceptions)
                    Console.Error.WriteLine("LOADER: " + loaderError);
            }
            return 1;
        }
    }

    private static void DumpRuntimeObject(string label, object value)
    {
        if (value == null)
            return;
        Type type = value.GetType();
        Console.WriteLine("GR2_RUNTIME label={0} type={1}", label, type.FullName);
        const BindingFlags flags = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance;
        foreach (FieldInfo field in type.GetFields(flags))
        {
            try
            {
                Console.WriteLine("GR2_RUNTIME_FIELD label={0} name={1} type={2} value={3}",
                    label, field.Name, field.FieldType.FullName, FormatRuntimeValue(field.GetValue(value)));
            }
            catch (Exception error)
            {
                Console.WriteLine("GR2_RUNTIME_FIELD label={0} name={1} error={2}",
                    label, field.Name, error.GetType().Name);
            }
        }
        foreach (PropertyInfo property in type.GetProperties(flags))
        {
            if (property.GetIndexParameters().Length != 0)
                continue;
            try
            {
                Console.WriteLine("GR2_RUNTIME_PROPERTY label={0} name={1} type={2} value={3}",
                    label, property.Name, property.PropertyType.FullName,
                    property.CanRead ? FormatRuntimeValue(property.GetValue(value, null)) : "<write-only>");
            }
            catch (Exception error)
            {
                Console.WriteLine("GR2_RUNTIME_PROPERTY label={0} name={1} error={2}",
                    label, property.Name, error.GetType().Name);
            }
        }
    }

    private static string FormatRuntimeValue(object value)
    {
        if (value == null)
            return "<null>";
        Array array = value as Array;
        if (array != null)
            return string.Format("{0}[{1}]", value.GetType().GetElementType().FullName, array.Length);
        System.Collections.ICollection collection = value as System.Collections.ICollection;
        if (collection != null)
            return string.Format("{0}(Count={1})", value.GetType().FullName, collection.Count);
        string text = value.ToString();
        return text.Length > 240 ? text.Substring(0, 240) + "..." : text;
    }

    private static string FormatTransform(IGrannyTransform transform)
    {
        if (transform == null)
            return "<null>";
        return string.Format(
            "flags={0};p={1};q={2};s={3}",
            transform.Flags, FormatArray(transform.Position),
            FormatArray(transform.Orientation), FormatArray(transform.ScaleShear));
    }

    private static string FormatArray(float[] values)
    {
        if (values == null)
            return "<null>";
        var strings = new string[values.Length];
        for (int index = 0; index < values.Length; index++)
            strings[index] = values[index].ToString("0.######", System.Globalization.CultureInfo.InvariantCulture);
        return string.Join(",", strings);
    }
}
