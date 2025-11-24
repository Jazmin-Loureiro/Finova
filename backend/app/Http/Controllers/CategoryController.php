<?php

namespace App\Http\Controllers;
use App\Models\Category;

use Illuminate\Http\Request;

class CategoryController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index(Request $request) {
    $query = Category::where('user_id', $request->user()->id)->where('active', true)->where('is_system', false);
        if ($request->has('type')) { 
            $query->where('type', $request->query('type')); 
        }
        $categories = $query->get(); 
        return response()->json([ 'categories' => $categories ], 200);
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request) {
        $request->validate([
            'name' => 'required|string|max:255',
            'type' => 'required|string|max:255',
            'color' => 'required|string|max:7', 
            'icon' => 'required|string|max:255',
        ]);
        //$category = new Category();
        $category = $request->user()->categories()->create([
        'name' => $request->name,
        'type' => $request->type,
        'color' => $request->color,
        'active' => true,
        'icon' => $request->icon,
    ]);
        return response()->json(['message' => 'Categoría creada con éxito', 'data' => $category], 201);
    }

    /**
     * Display the specified resource.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function show($id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, $id) {
        $request->validate([
            'name' => 'required|string|max:255',
            'color' => 'required|string|max:7',
            'icon' => 'required|string|max:255',
        ]);
        $category = Category::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->first();

        if (!$category) {
            return response()->json(['message' => 'Categoría no encontrada'], 404);
        }
         if ($category->is_default) {
        return response()->json([
            'error' => 'Esta categoría no puede ser editada.'
        ], 403);
    }
        $category->name = $request->name;
        $category->color = $request->color;
        $category->icon = $request->icon;
        $category->updated_at = now();
        $category->save();
        return response()->json(['message' => 'Categoría actualizada con éxito', 'data' => $category], 200);
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function destroy(Request $request, $id) {
        $category = Category::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->first();

        if (!$category) {
            return response()->json(['message' => 'Categoría no encontrada'], 404);
        }
        if ($category->is_default) {
        return response()->json([
            'error' => 'Esta categoría no puede ser eliminada.'
        ], 403);
    }

       $category->active = false;
       $category->updated_at = now();
       $category->save();


        return response()->json(['message' => 'Categoría eliminada con éxito'], 200);
        
    }
}
