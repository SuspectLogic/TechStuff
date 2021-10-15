"""
Generates unique materials for images in a selected directory.
Materials are just using the standard shader, and textures are plugged into the emission channel.
"""

import maya.cmds as cmds
import os # this module is needed for searching for files.

# file browser, starts from current scenes directory.
scenePath = cmds.file(q = True, l = True)
scenePath = str(scenePath[0])
scenePath = os.path.split(scenePath)[0]
imagePath = cmds.fileDialog2(cap = 'Choose Image Directory',fm = 3, ds = 2, dir = scenePath, okc = 'Accept')
imagePath = imagePath[0]

imageList = []

dir = os.listdir(imagePath)

for d in dir:
    if d.endswith('.png'):
        imageList.append(d)

for i in imageList:
    # remove extension from end of image names.
    i = os.path.splitext(i)[0]

    # Creates a new standardSurface mat with prefix of M_
    shd = cmds.shadingNode('standardSurface', name='M_' + i, asShader=True)
    
    # image file node
    file = cmds.shadingNode('file', asTexture=True)
    
    # creates a shading group    
    shdSG = cmds.sets(name = shd + 'SG', empty=True, renderable=True, noSurfaceShader=True)
    
    # Assigns texture file name to the shading group shader
    cmds.connectAttr(shd + '.outColor', shdSG + '.surfaceShader')
    
    # setup file node with textures.
    cmds.setAttr(file + '.fileTextureName', imagePath + '\\' + i + '.png', type = 'string')
    
    # attach file nodes to shader.
    cmds.connectAttr(file + '.outColor', shd +'.emissionColor')
    cmds.connectAttr(file + '.outAlpha', shd +'.opacity.opacityR')
    cmds.connectAttr(file + '.outAlpha', shd +'.opacity.opacityG')
    cmds.connectAttr(file + '.outAlpha', shd +'.opacity.opacityB')
    
    # sets attributes to make an unlit material
    cmds.setAttr(shd + '.emission', 1.0)
    cmds.setAttr(shd + '.base', 0.0)
    cmds.setAttr(shd + '.specular', 0.0)
