shader_type canvas_item;

// Variables personalizables
uniform vec4 color_rejilla : source_color = vec4(0.423, 0.6, 0.078, 1.0); // Color #6C9914
uniform int filas : hint_range(1, 100) = 15;
uniform int columnas : hint_range(1, 100) = 31;
uniform float tamano_cuadro : hint_range(1.0, 100.0) = 40.0;

void fragment() {
    // Calcular el tamaño total de la rejilla en pixeles
    vec2 tamano_total = vec2(float(columnas) * tamano_cuadro, float(filas) * tamano_cuadro);
    
    // Usar UV para obtener coordenadas locales (0 a 1) y escalarlas al tamaño total
    vec2 pos = UV * tamano_total;
    
    // Determinar en qué celda estamos
    vec2 celda = pos / tamano_cuadro;
    
    // Definir un umbral para el grosor de las líneas (puedes ajustar el valor)
    float umbral = 0.05;
    float linea_x = mod(celda.x, 1.0) < umbral ? 1.0 : 0.0;
    float linea_y = mod(celda.y, 1.0) < umbral ? 1.0 : 0.0;
    
    // Combinar las líneas horizontales y verticales
    float grid = max(linea_x, linea_y);
    
    // Dibujar la rejilla: fondo transparente (o negro) donde no hay línea, y el color elegido en las líneas
    COLOR = mix(vec4(0.0), color_rejilla, grid);
}
