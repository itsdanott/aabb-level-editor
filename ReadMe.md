# ToDo 
## Box Face Grab
* Implement face grabbing for the 3 axes. This can be useful for:
    * Scaling
    * Translating
    * Face Selecting (edit Texture + TexCoords)

## Box Cursor 
* The box cursor can be used for these editing actions:
    * translate the grid (height)
    * place a new aabb brush
    * place a new mesh
    * rotate the camera around the cursor



# Steps
## Adding a Line Renderer
## Adding plane struct and plane raycast  to determine box cursor face grabbing 
## After experimenting with plane -> simplification: simply use the XZ plane (with variable height)
## change from position to min max vectors for the box, as it has some benefits for calculation:
With the BoxPosition and Scale vector approach I managed to place the edit quad face to the corresponding position. 
But when working on the drag feature I noticed that the offset in rotation and position due to the BoxPosition vector approach 
also makes the exact preview position during harder to calculate as I would need to remove the offset while dragging.

Working with min max instead seems to be the easier solution!