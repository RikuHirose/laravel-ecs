<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\User;

class UserController extends Controller
{

    public function index()
    {
        
        return view('test', [
            'users' => User::all()
        ]);
    }
}