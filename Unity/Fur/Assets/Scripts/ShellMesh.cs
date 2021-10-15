using System.Collections;
using System.Collections.Generic;
using UnityEngine;
// using UnityEditor;
public class ShellMesh
{
    public bool AverageNormals = true;
    public float furLength;
    public int numberOfShells;
    public Mesh sourceMesh;
    private List<Color32> colors;
    private List<Vector3> Vertices;
    private List<Vector3> normals;
    private List<Vector4> tangents;
    private List<Vector2> uvs;
    private List<int> triangles;
    private List<Color> maskValues;
    private List<bool> toKeep = new List<bool>();
    public float offset;
    private List<Vector3> tempPos;
    public bool isSkinnedMesh;
    public List<BoneWeight> boneWeights;
    public Mesh CreateMesh()
    {
        // Initialize mesh data
        Vertices = new List<Vector3>();
        colors = new List<Color32>();
        uvs = new List<Vector2>();
        triangles = new List<int>();
        normals = new List<Vector3>();
        tangents = new List<Vector4>();
        tempPos = new List<Vector3>(sourceMesh.vertices);

        if(isSkinnedMesh)
        {
            boneWeights = new List<BoneWeight>();
        }
                
        offset = furLength * 0.01f;
        for(int i = 0; i < numberOfShells; i++)
        {
            int indexOffset = Vertices.Count;
            float curValue = i;
            curValue /= numberOfShells;
            if(Vertices.Count > 64000) Debug.LogError("Total number of vertices has exceeded the amount allowed. This might lead to problems in generating the mesh.");
            GenerateMeshData(curValue, indexOffset);
        }

        //Assign mesh data to mesh object.
        Mesh mesh = Object.Instantiate(sourceMesh);
        mesh.vertices = Vertices.ToArray();
        mesh.triangles = triangles.ToArray();
        mesh.normals = normals.ToArray();
        mesh.tangents = tangents.ToArray();
        mesh.uv = uvs.ToArray();
        mesh.colors32 = colors.ToArray();

        if(isSkinnedMesh)
        {
            mesh.boneWeights = boneWeights.ToArray();
        }
        
        return mesh;
    }
    private void GenerateMeshData(float curValue, int indexOffset)
    {
        for(int v = 0; v < sourceMesh.vertices.Length; v++)
        {
            normals.Add(sourceMesh.normals[v]);
            
            if(AverageNormals)
            {
                tangents.Add(new Vector4(1f,0f,0f,1f));
            }
            else
            {
                tangents.Add(sourceMesh.tangents[v]);
            } 
            
            uvs.Add(sourceMesh.uv[v]); 
            
            if(isSkinnedMesh) boneWeights.Add(sourceMesh.boneWeights[v]);
            
            tempPos[v] += (normals[v] * offset);
            Vertices.Add(tempPos[v]);

            // Assign vertex colors. Min value of .01 or greater is needed for proper stepping in the shader.
            if(curValue == 0) colors.Add(new Color32(((byte)(0.05 * 255)),0,0,0));
            else{colors.Add(new Color32(((byte)(curValue * 255)),0,0,0));}
        }
        
        //Append vertices in traingles. each 3 consectutive vertex is a single triangle.
        for(int t = 0; t < sourceMesh.triangles.Length; t++)
        {
            triangles.Add(indexOffset + sourceMesh.triangles[t]);
        }
    }
}
