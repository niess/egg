class Renderer
    constructor: (canvasId, shaderIds...) ->
        canvas = document.querySelector canvasId
        if !canvas
            throw "Could not find canvas with id = `#{id}`"
        gl = canvas.getContext "webgl"
        if !gl
            throw "Could not initialise WebGL for canvas with id = `#{id}`"

        getShaderById = do ->
            types =
                "x-shader/x-vertex": gl.VERTEX_SHADER
                "x-shader/x-fragment": gl.FRAGMENT_SHADER

            (id) ->
                element = document.getElementById id
                if !element
                    throw "could not load shader `#{id}`"
                type_attr = element.getAttribute "type"
                type = types[type_attr]
                if !types?
                    throw "unknown type `#{type_attr}` for shader `#{id}`"

                shader = gl.createShader type
                gl.shaderSource shader, element.text
                gl.compileShader shader
                if !gl.getShaderParameter shader, gl.COMPILE_STATUS
                    error = gl.getShaderInfoLog shader
                    gl.deleteShader shader
                    throw "while compiling shader `#{id}`: #{error}"
                return shader

        shaderProgram = do gl.createProgram
        for id in shaderIds
            shader = getShaderById id
            gl.attachShader shaderProgram, shader
        gl.linkProgram shaderProgram

        if !gl.getProgramParameter shaderProgram, gl.LINK_STATUS
            throw "Could not link shaders"
        gl.useProgram shaderProgram

        shaderProgram.location =
            vertex: gl.getAttribLocation shaderProgram, "vertex"

        gl.clearColor 0.5, 0.5, 0.5, 0.9
        gl.enable gl.DEPTH_TEST
        gl.viewport 0,0, canvas.width, canvas.height

        [@canvas, @gl, @shaderProgram] = [canvas, gl, shaderProgram]


    update: (geometry) =>
        gl = @gl
        gl.clear gl.COLOR_BUFFER_BIT
        indices = geometry.buffers.indices
        gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, indices
        gl.drawElements gl.TRIANGLES, geometry.size, gl.UNSIGNED_SHORT, 0


class Camera
    constructor: (renderer, kwargs) ->
        canvas = renderer.canvas
        if kwargs?
            {fov, aspect, near, far, position, rotation} = kwargs
        fov ?= 45 * Math.PI / 180
        aspect ?= canvas.width / canvas.height
        near ?= 0.1
        far ?= 100

        @projection = do glMatrix.mat4.create
        glMatrix.mat4.perspective(@projection, fov, aspect, near, far)

        @view = do glMatrix.mat4.create
        if position?
            @translate position...

        # Set the uniforms for the shader
        [gl, shaderProgram] = [renderer.gl, renderer.shaderProgram]
        gl.uniformMatrix4fv(
            gl.getUniformLocation(shaderProgram, "projection")
            false
            @projection
        )
        gl.uniformMatrix4fv(
            gl.getUniformLocation(shaderProgram, "view")
            false
            @view
        )

    translate: (x, y, z) ->
        glMatrix.mat4.translate @view, @view, [-x, -y, -z]


class Geometry
    constructor: (renderer, vertices, indices) ->
        [gl, shaderProgram] = [renderer.gl, renderer.shaderProgram]

        # Create and fill the vertex buffer
        vertexBuffer = do gl.createBuffer
        gl.bindBuffer gl.ARRAY_BUFFER, vertexBuffer
        gl.bufferData(
            gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW)
        gl.vertexAttribPointer(
            shaderProgram.location.vertex, 4, gl.FLOAT, false, 0, 0)
        gl.enableVertexAttribArray shaderProgram.location.vertex
        gl.bindBuffer gl.ARRAY_BUFFER, null

        # Create and fill the index buffer
        indexBuffer = do gl.createBuffer
        gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, indexBuffer
        gl.bufferData(
            gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(indices), gl.STATIC_DRAW)
        gl.bindBuffer gl.ARRAY_BUFFER, null

        @buffers =
            vertices: vertexBuffer
            indices: indexBuffer
        @size = indices.length


main = ->
    r = new Renderer "#glCanvas", "egg-vs", "egg-fs"
    [canvas, gl, shaderProgram] = [r.canvas, r.gl, r.shaderProgram]

    vertices = [-0.5, 0.5, 0.0, 0,  -0.5, -0.5, 0.0, 0,  0.5, -0.5, 0.0, 0,
                 0.5, 0.5, 0.0, 0]
    indices = [0, 1, 2, 2, 3, 0]
    geometry = new Geometry r, vertices, indices
    camera = new Camera r,
        position: [0.0, 0.0, 8.0]

    r.update geometry


do main
