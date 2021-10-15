using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TextureToMeshMask
{
    public List<Color> GetValuesAtPoint(Mesh baseShell, Texture2D furMask, List<Color> maskValues)
    {
        maskValues = new List<Color>();
        Vector2[] sourceUVS = baseShell.uv;
        Vector3[] sourceVerts = baseShell.vertices;
        for(int v = 0; v < baseShell.vertices.Length; v++)
        {
            Vector2 uv = baseShell.uv[v];
            var currentPixel = furMask.GetPixelBilinear(uv.x, uv.y);
        }

        foreach(Vector2 uv in sourceUVS)
        {
            var currentPixel = furMask.GetPixelBilinear(uv.x,uv.y);
            maskValues.Add(currentPixel); // Adds pixel values to a list.
        }
        return maskValues;
    }
}
