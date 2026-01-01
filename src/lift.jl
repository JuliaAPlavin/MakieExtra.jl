### https://github.com/MakieOrg/Makie.jl/pull/3915

# mimick Observables.jl map() signature to forward directly:
lift(f, arg::Makie.AbstractObservable, args...; kwargs...) = map(f, arg, args...; kwargs...)
# handle the general case:
function lift(f, args...; kwargs...)
    if !any(a -> isa(a, Makie.AbstractObservable), args)
        # there are no observables
        f(args...)
    else
        # there are observables, but not in the first position
        lift((_, as...) -> f(as...), Observable(nothing), args...; kwargs...)
    end
end


function liftT(f::Function, T::Type, args...)
    res = Observable{T}(f(to_value.(args)...))
    map!(f, res, args...)
    return res
end


"""
Returns a set of all sub-expressions in an expression that look like \$some_expression
"""
function find_observable_expressions(obj::Expr)
    observable_expressions = Set()
    if is_interpolated_observable(obj)
        push!(observable_expressions, obj)
    else
        for a in obj.args
            observable_expressions = union(observable_expressions, find_observable_expressions(a))
        end
    end
    return observable_expressions
end

# empty dict if x is not an Expr
find_observable_expressions(x) = Set()

is_interpolated_observable(x) = false
function is_interpolated_observable(e::Expr)
    e.head == Symbol(:$) && length(e.args) == 1
end

"""
Replaces every subexpression that looks like a observable expression with a substitute symbol stored in `exprdict`.
"""
function replace_observable_expressions(exp::Expr, exprdict)
    if is_interpolated_observable(exp)
        exprdict[exp]
    else
        Expr(exp.head, replace_observable_expressions.(exp.args, Ref(exprdict))...)
    end
end

replace_observable_expressions(x, exprdict) = x

"""
Replaces an expression with `lift(argtuple -> expression, args...)`, where `args`
are all expressions inside the main one that begin with \$.

# Example:

```julia
x = Observable(rand(100))
y = Observable(rand(100))
```

## before
```julia
z = lift((x, y) -> x .+ y, x, y)
```

## after
```julia
z = @lift(\$x .+ \$y)
```

You can also use parentheses around an expression if that expression evaluates to an observable.

```julia
nt = (x = Observable(1), y = Observable(2))
@lift(\$(nt.x) + \$(nt.y))
```
"""
macro lift(exp)
    exp = @modify(exp |> RecursiveOfType(Expr) |> If(e -> Base.isexpr(e, :macrocall) && e.args[1] == Symbol("@f_str"))) do e
        macroexpand(__module__, e; recursive=true)
    end

    observable_expr_set = find_observable_expressions(exp)

    # store expressions with their substitute symbols, gensym them manually to be
    # able to escape the expression later
    observable_expr_arg_dict = Dict(expr => gensym("arg$i") for (i, expr) in enumerate(observable_expr_set))

    exp = replace_observable_expressions(exp, observable_expr_arg_dict)

    # keep an array for ordering
    observable_expressions_array = collect(keys(observable_expr_arg_dict))
    observable_substitutes_array = [observable_expr_arg_dict[expr] for expr in observable_expressions_array]
    observable_expressions_without_dollar = [n.args[1] for n in observable_expressions_array]

    # the arguments to the lifted function
    argtuple = Expr(Symbol(:tuple), observable_substitutes_array...)

    # the lifted function itself
    function_expression = Expr(Symbol(:->), argtuple, exp)

    if Base.isexpr(exp, Symbol("::"))
        # the full expression
        T = exp.args[2]
        return Expr(
            Symbol(:call),
            Symbol(:liftT),
            esc(function_expression),
            esc(T),
            esc.(observable_expressions_without_dollar)...
        )
    else
        # the full expression
        return Expr(
            Symbol(:call),
            Symbol(:lift),
            esc(function_expression),
            esc.(observable_expressions_without_dollar)...
        )
    end
end
