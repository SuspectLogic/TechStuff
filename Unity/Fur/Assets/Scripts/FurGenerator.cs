using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

/*
Done:
- Coverage mask: Optimizes the generated mesh, removing triangles below a given threshold.
    Implementation: Tooling & Shader
- Support for MeshFilters and SkinnedMeshRenderers.

ToDo:
- Height mask: Height multiplier for a given area. (this affects vertices only.)
    Implementation: Tooling or Shader. This mask would act as an additional multiplier to the "offset" variable. 
        
- Density mask: This is helpful whenever you want thicker/thinner hairs in given areas. (uv scale multiplier)
    Implementation: Shader
        0.5 = no effect.
        0 = Thinnest.
        1 = Thickest.
- 
*/
public class FurGenerator : MonoBehaviour
{
    // UI properties
    [SerializeField]
    private Material furMat;
    [SerializeField]
    private Material finMat;
    [SerializeField]
    private bool UseMask;
    [SerializeField]
    private bool AverageNormals = true;
    
    [SerializeField]
    private float furLength;

    [SerializeField]
    [Range(0,50)]
    private int numberOfShells;

    [HideInInspector]
    public string path;

    [SerializeField]
    [Range(0,1)]
    private float threshold = 0.1f;
    [SerializeField]
    private bool GenerateFins = false;
    [SerializeField]
    private bool LimitFins;
    public enum finType{Extruded, Square, Sharp}
    public finType finShape;

    [SerializeField]
    private int finCount;
    [SerializeField]
    private float finWidthMax;
    [SerializeField]
    private float finWidthMin;
    [SerializeField]
    private float finHeightMax;
    [SerializeField]
    private float finHeightMin;
    [SerializeField]
    [Range(1,4)]
    private int finSegments;
    private Mesh sourceMesh;
    private List<Color> maskValues;
    private List<bool> toKeep = new List<bool>();
    private GameObject shellContainer;
    private GameObject finContainer;
    private bool isSkinnedMesh = false;
    private Mesh furMesh;
    private Mesh finMesh;
        
    // Main function caller.
    public void GenerateMesh()
    {
        if(numberOfShells < 1)
        {
            Debug.Log("Requires at least 1 fur shell.");
            return;
        }

        sourceMesh = CreateSourceMesh();
        shellContainer = MakeContainers("_ShellContainer", furMat);

        //Generate Shells
        var shellObject = new ShellMesh();
        shellObject.numberOfShells = this.numberOfShells;
        shellObject.sourceMesh = this.sourceMesh;
        shellObject.furLength = this.furLength;

        furMesh = shellObject.CreateMesh();

        // Generate Fins        
        if(GenerateFins)
        {
            finContainer = MakeContainers("_FinContainer", finMat);

            // Set properties for class
            var finObject = new FinMesh();

            finObject.sourceMesh = this.sourceMesh;
            finObject.LimitFins = this.LimitFins;
            finObject.finCount = this.finCount;
            finObject.finSegments = this.finSegments;            
            finObject.finHeightMin = this.finHeightMin;
            finObject.finHeightMax = this.finHeightMax;
            finObject.finWidthMin = this.finWidthMin;
            finObject.finWidthMax = this.finWidthMax;
            finObject.finMat = this.finMat;
            
            finMesh = finObject.CreateFinMesh(isSkinnedMesh, finShape.ToString());
        }

        SetMesh(shellContainer, furMesh);

        if(GenerateFins)
        {
            SetMesh(finContainer, finMesh);
        }
    }
    public void SaveMesh()
    {
        string name = gameObject.name;        
        AssetDatabase.CreateAsset(furMesh, path);
        AssetDatabase.SaveAssets();
    }
    private GameObject MakeContainers(string name, Material mat)
    {
        GameObject obj = GameObject.Find(gameObject.name + name);

        if(obj != null)
        {
            DestroyImmediate(obj, true);
        }

        obj = new GameObject();
        obj.name = gameObject.name + name;
        obj.transform.parent = gameObject.transform.parent;
        obj.transform.localPosition = gameObject.transform.localPosition;
        obj.transform.localRotation = gameObject.transform.localRotation;
        obj.transform.localScale = gameObject.transform.localScale;

        if(TryGetComponent<SkinnedMeshRenderer>(out SkinnedMeshRenderer sr))
        {
            Debug.Log("Made it here");
            var ren = obj.AddComponent<SkinnedMeshRenderer>();
            ren = ren.GetCopyOf(sr);
            ren.sharedMaterial = mat;
            isSkinnedMesh = true;
        }
        else if(TryGetComponent<MeshFilter>(out MeshFilter mr))
        {
            obj.AddComponent<MeshFilter>();
            var ren = obj.AddComponent<MeshRenderer>();
            ren.sharedMaterial = mat;
        }
        
        return obj;
    }
    private Mesh CreateSourceMesh()
    {
        Mesh sampledMesh = new Mesh();
        if(isSkinnedMesh) sampledMesh = gameObject.GetComponent<SkinnedMeshRenderer>().sharedMesh;
        else {sampledMesh = gameObject.GetComponent<MeshFilter>().sharedMesh;}

        // ALters source mesh
        List<Vector2> srcUVS = new List<Vector2>(sampledMesh.uv);
        List<Vector3> srcVertices = new List<Vector3>(sampledMesh.vertices);
        List<Vector3> srcNorm = new List<Vector3>(sampledMesh.normals);
        List<Vector4> srcTangents = new List<Vector4>(sampledMesh.tangents);
        List<int> srcTris = new List<int>(sampledMesh.triangles);
        List<int> tempTris = new List<int>();
                
        if(UseMask) // Generates Optimized Source Mesh.
        {
            srcTris = new List<int>();
            if(furMat.GetTexture("_MaskTex") == null) Debug.LogWarning("Warning, not mask texture was found. This could lead to non-optimized fur generation.");
            
            maskValues = new List<Color>();
            TextureToMeshMask textureToMeshMask = new TextureToMeshMask();
            Texture2D furMask = furMat.GetTexture("_MaskTex") as Texture2D;
            maskValues = textureToMeshMask.GetValuesAtPoint(sampledMesh, furMask, this.maskValues);

            // Create bools list of verts to remove.
            for(int v = 0; v < sampledMesh.vertices.Length; v++)
            {
                if(maskValues[v].r < threshold || maskValues[v].g < threshold || maskValues[v].b < threshold) toKeep.Add(false);
                else { toKeep.Add(true); }
            }


            // Add triangles to list only if they meet a condition.
            for(int t = 0; t < sampledMesh.triangles.Length; t+=3)
            {
                int triangleA = sampledMesh.triangles[t];
                int triangleB = sampledMesh.triangles[t+1];
                int triangleC = sampledMesh.triangles[t+2];

                if(toKeep[triangleA] || toKeep[triangleB] || toKeep[triangleC])
                {
                    srcTris.Add(triangleA);
                    srcTris.Add(triangleB);
                    srcTris.Add(triangleC);
                }
            }

            if(isSkinnedMesh) tempTris = new List<int>(srcTris);

            int index = 0;
            while(index < srcVertices.Count)
            {                
                if(srcTris.Contains(index))
                {
                    index++;
                }
                else
                {
                    srcVertices.RemoveAt(index);
                    srcUVS.RemoveAt(index);
                    srcNorm.RemoveAt(index);
                    srcTangents.RemoveAt(index);
                    
                    for(int i = 0; i < srcTris.Count; i++)
                    {
                        if(srcTris[i] > index) srcTris[i]--;
                    }
                }
            }
        }
        
        Mesh mesh = new Mesh();

        if(isSkinnedMesh) // mesh instantiation is slower, but necessary too carry over compatibility for optimized rigs.
        {
            mesh = Instantiate(sampledMesh);
            mesh.triangles = srcTris.ToArray();
            mesh.vertices = srcVertices.ToArray();
            List<BoneWeight> srcWeights = new List<BoneWeight>(sampledMesh.boneWeights);

            if(UseMask)
            {
                for(int vIndex = sampledMesh.vertices.Length - 1; vIndex >= 0 ; vIndex--)                
                {
                    if(!tempTris.Contains(vIndex))
                    {
                        srcWeights.RemoveAt(vIndex);
                    }
                }
            }
            mesh.boneWeights = srcWeights.ToArray();
        }
        else
        {
            mesh.vertices = srcVertices.ToArray();
            mesh.triangles = srcTris.ToArray();
        }

        if(AverageNormals) 
        {
            srcNorm = CalculateNormals(srcNorm, srcTris, srcVertices);
            for(int i = 0; i < srcNorm.Count; i++)
            {
                Vector4 currentTangent = new Vector4(1f,0f,0f,1f);
                srcTangents[i] = currentTangent;
            }
        }

        mesh.normals = srcNorm.ToArray();
        mesh.tangents = srcTangents.ToArray();        
        mesh.uv = srcUVS.ToArray();
        return mesh;
    }
    List<Vector3> CalculateNormals(List<Vector3> n, List<int> tris, List<Vector3> verts)
    {
        var vertexNormals = new List<Vector3>(n);
        for(int i = 0; i < tris.Count/3; i++)
        {
            int triangleIndex = i * 3;
            int normalIndexA = tris[triangleIndex];
            int normalIndexB = tris[triangleIndex+1];
            int normalIndexC = tris[triangleIndex+2];

            Vector3 triangleNormal = SurfaceNormalAtIndex(verts, normalIndexA, normalIndexB, normalIndexC);

            vertexNormals[normalIndexA] += triangleNormal;
            vertexNormals[normalIndexB] += triangleNormal;
            vertexNormals[normalIndexC] += triangleNormal;
        }

        for(int i = 0; i < vertexNormals.Count; i++)
        {
            vertexNormals[i].Normalize();
        }

        return vertexNormals;
    }

    Vector3 SurfaceNormalAtIndex(List<Vector3> verts, int normalA, int normalB, int normalC)
    {
        Vector3 pointA = verts[normalA];
        Vector3 pointB = verts[normalB];
        Vector3 pointC = verts[normalC];

        Vector3 sideAB = pointB - pointA;
        Vector3 sideAC = pointC - pointA;
        return Vector3.Cross(sideAB, sideAC).normalized;        
    }

    private void SetMesh(GameObject go, Mesh mesh)
    {
        if(isSkinnedMesh)
        {
            var renderer = go.GetComponent<SkinnedMeshRenderer>();
            renderer.sharedMesh = mesh;
        }
        else
        {
            go.GetComponent<MeshFilter>().sharedMesh = mesh;
        }
    }    
}

