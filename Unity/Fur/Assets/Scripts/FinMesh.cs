using System.Collections;
using System.Collections.Generic;
using UnityEngine;
public class FinMesh
{
    public Material finMat;
    public bool LimitFins;
    public int finCount;
    public float finWidthMax;
    public float finWidthMin;
    public float finHeightMax;
    public float finHeightMin;
    public int finSegments;    
    public Mesh sourceMesh;
    private List<Vector3> finVerts;
    private List<Color32> finColors;
    private List<Vector3> finNormals;
    private List<Vector4> finTangents;
    private List<Vector2> finUVS;
    private List<int> finTris;
    private List<BoneWeight> finWeights;
    public Mesh CreateFinMesh(bool isSkinnedMesh, string finShape)
    {
        Mesh finMesh = new Mesh();
        finVerts = new List<Vector3>();
        finColors = new List<Color32>();        
        finNormals = new List<Vector3>();
        finTangents = new List<Vector4>();
        finUVS = new List<Vector2>();
        finTris = new List<int>();
        finWeights = new List<BoneWeight>();
        List<int[]> triList = new List<int[]>();

        for(int i = 0; i < sourceMesh.triangles.Length; i+=3 )
        {
            triList.Add(new int[]{sourceMesh.triangles[i], sourceMesh.triangles[i+1], sourceMesh.triangles[i+2]});
        }

        int index = 0;
        int triIndex = 0;
        
        if(LimitFins)
        {
            for(int v = 0; v < finCount; v++)
            {
                switch(finShape)
                {
                    case "Sharp":
                        GenerateSharpFin(index, sourceMesh);
                        break;
                    case "Square":
                        GenerateSquareFin(index, sourceMesh);
                        break;
                    case "Extruded":
                        GenerateExtrudedFin(index, sourceMesh, triList);
                        break;                
                }            
            }
        }
        else
        {
            for(int t = 0; t < triList.Count; t++)
            {
                GenerateFin(index, sourceMesh, triList, triIndex);
                triIndex +=2;
                index ++;
            }
        }
        
        finMesh.vertices = finVerts.ToArray();
        finMesh.triangles = finTris.ToArray();
        finMesh.uv = finUVS.ToArray();
        finMesh.colors32 = finColors.ToArray();
        finMesh.RecalculateNormals();

        finNormals = CalculateNormals(new List<Vector3>(finMesh.normals), finTris, finVerts);

        for(int i = 0; i < finVerts.Count; i++)
        {
            Vector4 currentTangent = new Vector4(1f,0f,0f,1f);
            finTangents[i] = currentTangent;
        }

        finMesh.normals = finNormals.ToArray();
        finMesh.tangents = finTangents.ToArray();

        if(isSkinnedMesh)
        {
            finMesh.boneWeights = finWeights.ToArray();
        }

        Debug.Log("Fin vertex count: " + finVerts.Count);

        return finMesh;
    }

    void GenerateSharpFin(int index, Mesh sourceMesh)
    {
        index = finVerts.Count; // Vertex index for setting triangles.
        var height =  UnityEngine.Random.Range(finHeightMin,finHeightMax);
        var width = UnityEngine.Random.Range(finWidthMin,finWidthMax);
        var randomInt = UnityEngine.Random.Range(0, sourceMesh.vertices.Length);
        var position = sourceMesh.vertices[randomInt];
        var normal = sourceMesh.normals[randomInt];
        Quaternion randomRotation = Quaternion.AngleAxis(UnityEngine.Random.Range(-360f,360f), normal);
        //Build 2 verts for each segment. Starting with base.
        for(var i = 0; i < finSegments; i++)
        {
            float forward = 0.001f;
            
            float t = (float)i / finSegments;
            forward = Mathf.Pow(t, forward);
            float segmentHeight = height * t;
            float segmentWidth = width * (1 - t);
            var vert0 = GenerateVertex(position,normal, segmentWidth, segmentHeight, randomRotation);
            var vert1 = GenerateVertex(position,normal, -segmentWidth, segmentHeight, randomRotation);
            
            finVerts.Add(vert0);
            finVerts.Add(vert1);

            var uv0 = new Vector2(0f, t);
            var uv1 = new Vector2(1f, t);

            finUVS.Add(uv0);
            finUVS.Add(uv1);
            
            finColors.Add(new Color32(((byte)(t * 255)),((byte)(t * 255)),0,0));
            finColors.Add(new Color32(((byte)(t * 255)),((byte)(t * 255)),0,0));
        }

        // Segment = 1      Segment = 2     Segment = 3    Segment = 4     Segment = 5     Segment = 6
        // 0,1,2 - Tri     2,1,3 - Tri     2,3,4 - Tri     4,3,5 - Tri     4,5,6 - Tri      6,5,7

        // Add triangles.
        for(int i = 0; i < finSegments * 2 - 1; i++)
        {
            if(i % 2 == 0) //1,3,5
            {
                finTris.Add(index);  // 0, 2
                finTris.Add(index+1);// 1, 3
                finTris.Add(index+2);// 2, 4
            }
            else
            {
                finTris.Add(index+2); // 2, 4
                finTris.Add(index+1); // 1, 3
                finTris.Add(index+3); // 3, 5
                index += 2;
            }
        }

        var endVert = position + (normal * height);
        finVerts.Add(endVert);
        finUVS.Add(new Vector2(0.5f, 1f));
        finColors.Add(new Color32(255,255,255,255));
    }

    private Vector3 GenerateVertex(Vector3 pos, Vector3 norm, float width, float height, Quaternion rotation)
    {
        Vector3 transform = new Vector3(width, 0f, 0f);
        var newPos = pos;
        newPos += (norm * height);
        newPos += transform;
        newPos = rotation * (newPos - pos) + pos;
        return newPos;
    }

    void GenerateSquareFin(int index, Mesh sourceMesh)
    {
        index = finVerts.Count; // Vertex index for setting triangles.
        var height =  UnityEngine.Random.Range(finHeightMin, finHeightMax);
        var width = UnityEngine.Random.Range(finWidthMin, finWidthMax) * 4;
        var randomInt = UnityEngine.Random.Range(0, sourceMesh.vertices.Length);
        var position = sourceMesh.vertices[randomInt];
        var normal = sourceMesh.normals[randomInt];
        Quaternion randomRotation = Quaternion.AngleAxis(UnityEngine.Random.Range(-360f,360f), normal);

        var vert0 = position;
        var vert1 = position;
        vert0 += new Vector3(width, 0f, 0f);
        vert1 += new Vector3(-width, 0f, 0f);
        vert0 = randomRotation * (vert0 - position) + position;
        vert1 = randomRotation * (vert1 - position) + position;
        finVerts.Add(vert0);
        finVerts.Add(vert1);

        var vert2 = position + (normal * height);
        var vert3 = vert2;
        vert2 += new Vector3(width, 0f, 0f);
        vert3 += new Vector3(-width, 0f, 0f);
        vert2 = randomRotation * (vert2 - position) + position;
        vert3 = randomRotation * (vert3 - position) + position;
        finVerts.Add(vert2);
        finVerts.Add(vert3);

        var uv0 = new Vector2(0f, 0f);
        var uv1 = new Vector2(1f, 0f);
        var uv2 = new Vector2(0f, 1f);
        var uv3 = new Vector2(1f, 1f);       
        

        finUVS.Add(uv0);
        finUVS.Add(uv1);
        finUVS.Add(uv2);
        finUVS.Add(uv3);
        
        finColors.Add(new Color32(0,0,0,0));
        finColors.Add(new Color32(0,0,0,0));
        finColors.Add(new Color32(255,255,0,0));
        finColors.Add(new Color32(255,255,0,0));

        finTris.Add(index);  // 0
        finTris.Add(index+1);// 1
        finTris.Add(index+2);// 2
        
        finTris.Add(index+2);// 2
        finTris.Add(index+1);// 1
        finTris.Add(index+3);// 3
    }
    void GenerateExtrudedFin(int index, Mesh sourceMesh, List<int[]> triList)
    {
        index = finVerts.Count; // Vertex index for setting triangles.
        var height =  UnityEngine.Random.Range(finHeightMin, finHeightMax);

        // initialize triangle data.        
        var position0 = Vector3.zero;
        var position1 = Vector3.zero;
        var position2 = Vector3.zero;

        var randomStep = UnityEngine.Random.Range(0, triList.Count);
        position0 = sourceMesh.vertices[triList[randomStep][0]];
        position1 = sourceMesh.vertices[triList[randomStep][1]];
        position2 = sourceMesh.vertices[triList[randomStep][2]];
        
        var pA = position1 - position0;
        var pB = position2 - position0;
        var normal = Vector3.Cross(pA, pB).normalized;
                
        var vert0 = position0;
        var vert1 = position1;
        var vert2 = position0 + (normal * (height));
        var vert3 = position1 + (normal * (height));

        finVerts.Add(vert0);
        finVerts.Add(vert1);
        finVerts.Add(vert2);
        finVerts.Add(vert3);

        var uv0 = new Vector2(0f, 0f);
        var uv1 = new Vector2(1f, 0f);
        var uv2 = new Vector2(0f, 1f);
        var uv3 = new Vector2(1f, 1f);

        finUVS.Add(uv0);
        finUVS.Add(uv1);
        finUVS.Add(uv2);
        finUVS.Add(uv3);
        
        finColors.Add(new Color32(0,0,0,0));
        finColors.Add(new Color32(0,0,0,0));
        finColors.Add(new Color32(255,255,0,0));
        finColors.Add(new Color32(255,255,0,0));
        
        finTangents.Add(new Vector4(1f,0f,0f,1f));
        finTangents.Add(new Vector4(1f,0f,0f,1f));
        finTangents.Add(new Vector4(1f,0f,0f,1f));
        finTangents.Add(new Vector4(1f,0f,0f,1f));

        finTris.Add(index);  // 0
        finTris.Add(index+1);// 1
        finTris.Add(index+2);// 2
        
        finTris.Add(index+2);// 2
        finTris.Add(index+1);// 1
        finTris.Add(index+3);// 3
    }

    void GenerateFin(int index, Mesh sourceMesh, List<int[]> triList, int triIndex)
    {
        Debug.Log(index);
        var height =  UnityEngine.Random.Range(finHeightMin, finHeightMax);
        
        var position0 = sourceMesh.vertices[triList[index][0]];
        var position1 = sourceMesh.vertices[triList[index][1]];
        var position2 = sourceMesh.vertices[triList[index][2]];
        
        var pA = position1 - position0;
        var pB = position2 - position0;
        var normal = Vector3.Cross(pA, pB).normalized;
                
        var vert0 = position0;
        var vert1 = position1;
        var vert2 = position0 + (normal * (height));
        var vert3 = position1 + (normal * (height));

        finVerts.Add(vert0);
        finVerts.Add(vert1);
        finVerts.Add(vert2);
        finVerts.Add(vert3);

        var uv0 = new Vector2(0f, 0f);
        var uv1 = new Vector2(1f, 0f);
        var uv2 = new Vector2(0f, 1f);
        var uv3 = new Vector2(1f, 1f);

        finUVS.Add(uv0);
        finUVS.Add(uv1);
        finUVS.Add(uv2);
        finUVS.Add(uv3);
        
        finColors.Add(new Color32(0,0,0,0));
        finColors.Add(new Color32(0,0,0,0));
        finColors.Add(new Color32(255,255,0,0));
        finColors.Add(new Color32(255,255,0,0));
        
        finTangents.Add(new Vector4(1f,0f,0f,1f));
        finTangents.Add(new Vector4(1f,0f,0f,1f));
        finTangents.Add(new Vector4(1f,0f,0f,1f));
        finTangents.Add(new Vector4(1f,0f,0f,1f));

        finTris.Add(triIndex);  // 0
        finTris.Add(triIndex+1);// 1
        finTris.Add(triIndex+2);// 2
        
        finTris.Add(triIndex+2);// 2
        finTris.Add(triIndex+1);// 1
        finTris.Add(triIndex+3);// 3
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
}
