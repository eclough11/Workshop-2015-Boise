-- Copyright 2014-2015: Mike Dipasquale
-- You may redistribute this file under the terms of the GNU General Public
-- License as published by the Free Software Foundation, either version 2
-- of the License, or any later version.

------------------------------------------
------------------------------------------
-- Header
------------------------------------------
------------------------------------------

if version#"VERSION" <= "1.4" then (
    needsPackage "Graphs",
    needsPackage "Polyhedra"
    )

newPackage select((
    "AlgebraicSplines",
        Version => "0.1.0", 
        Date => "27. May 2015",
        Authors => {
            {Name => "Mike DiPasquale", Email => "midipasq@gmail.com", HomePage => "http://illinois.edu/~dipasqu1"},
            {Name => "Gwyn Whieldon", Email => "whieldon@hood.edu", HomePage => "http://cs.hood.edu/~whieldon"},
	    {Name => "Eliana Duarte", Email => "emduart2@illinois.edu", HomePage => "http://illinois.edu/~emduart2"},
	    {Name => "Daniel Irving Bernstein", Email=> "dibernst@ncsu.edu", HomePage =>"http://www4.ncsu.edu/~dibernst"}
        },
        Headline => "Package for computing topological boundary maps and piecewise continuous splines on polyhedral complexes.",
        Configuration => {},
        DebuggingMode => true,
        if version#"VERSION" > "1.4" then PackageExports => {
	    "Polyhedra",
	    "Graphs"
	    }
        ), x -> x =!= null)

if version#"VERSION" <= "1.4" then (
    needsPackage "Polyhedra",
    needsPackage "Graphs"
    )

export {
   "Splines",
   "VertexCoordinates",
   "Regions",
   "SplineModule",
   "splines",
   "Spline",
   "spline",
   "formsList",
   "splineMatrix",
   "splineModule",
   "InputType",
   "ByFacets",
   "ByLinearForms",
   "isHereditary",
   "CheckHereditary",
   "Homogenize",
   "VariableName",
   "getCodimIFacesPolytope",
   "getCodimIFacesSimplicial",
   "interiorFaces",
   "splineDimTable",
   "posNum",
   "hilbertCTable",
   "hilbertPolyEval",
   "generalizedSplines",
   "issimplicial"
    }

------------------------------------------
------------------------------------------
-- Data Types and Constructors
------------------------------------------
------------------------------------------

--Create an object that gives ALL splines
--on a given subdivision.
Splines = new Type of HashTable
splines = method(Options => {
	symbol InputType => "ByFacets", 
	symbol CheckHereditary => false, 
	symbol Homogenize => true, 
	symbol VariableName => getSymbol "t",
	symbol CoefficientRing => QQ})

splines(List,List,List,ZZ) := Matrix => opts -> (V,F,E,r) -> (
    	AD := splineMatrix(V,F,E,r,opts);
	K := ker AD;
	b := #F;
    	new Splines from {
	    symbol cache => new CacheTable from {"name" => "Unnamed Spline"},
	    symbol VertexCoordinates => V,
	    symbol Regions => F,
	    symbol SplineModule => image submatrix(gens K, toList(0..b-1),)
	}
)


net Splines := S -> S.SplineModule


Spline = new Type of HashTable

spline = method()
spline(Splines,List) := (S,L) -> (
    M := S.SplineModule;
    
    )
   


------------------------------------------
------------------------------------------
-- Methods
------------------------------------------
------------------------------------------

------------------------------------------
------------------------------------------
isHereditary= method()
------------------------------------------
------------------------------------------
-- This method checks if the polyhedral
-- complex with facets and edges (F,E)
-- is hereditary.
------------------------------------------
--Inputs: 
------------------------------------------
--F = ordered lists of facets
--E = list of edges
------------------------------------------
--Outputs:
--Boolean, if complex is hereditary
------------------------------------------

isHereditary(List,List) := Boolean => (F,E) -> (
    V := unique flatten join F;
    dualV := toList(0..#F-1);
    dualE := apply(#E, e-> positions(F, f-> all(E_e,v-> member(v,f))));
    if not all(dualE,e-> #e <= 2) then (
	false -- Checks pseudo manifold condition
      ) else (
      dualG := graph(dualE,EntryMode=>"edges");
      linkH := hashTable apply(V, v-> v=>select(#F, f -> member(v,F_f)));
      -- Checks if the link of each vertex is connected.
      all(keys linkH, k-> isConnected inducedSubgraph(dualG,linkH#k))
      )
)

isHereditary(List) := Boolean => F -> (
    V := unique flatten join F;
    E := getCodimIFacesSimplicial(F,1);
    dualV := toList(0..#F-1);
    dualE := apply(#E, e-> positions(F, f-> all(E_e,v-> member(v,f))));
    if not all(dualE,e-> #e <= 2) then (
	false -- Checks pseudo manifold condition
      ) else (
      dualG := graph(dualE,EntryMode=>"edges");
      linkH := hashTable apply(V, v-> v=>select(#F, f -> member(v,F_f)));
      -- Checks if the link of each vertex is connected.
      all(keys linkH, k-> isConnected inducedSubgraph(dualG,linkH#k))
      )
)


-----------------------------------------
-----------------------------------------
interiorFaces = method()
-----------------------------------------
-----------------------------------------
--Inputs: 
-----------------------------------------
--F = list of facets
--E = list of codimension 1 faces
-- (possibly including non-interior)
-----------------------------------------
-----------------------------------------
--Outputs:
-----------------------------------------
--E' = list of interior edges
-----------------------------------------
interiorFaces(List,List) := List => (F,E) -> (
    --Compute which facets are adjacent to each edge:
    facetEdgeH := apply(#E, e-> positions(F, f-> all(E_e,v-> member(v,f))));
    --Compute indices of interior edges, and replace edge list and 
    --facet adjacencies to only include these interior edges:
    indx := positions(facetEdgeH, i-> #i === 2);
    E_indx
    )

------------------------------------------
------------------------------------------
getCodim1FacesPolytope = method()
------------------------------------------
------------------------------------------
--Inputs: 
------------------------------------------
--F = list of facets of a polytopal complex
------------------------------------------
--Outputs:
-----------------------------------------
--E = list of (interior) codim 1 faces
-----------------------------------------

getCodim1FacesPolytope(List) := List => F ->(
    --This function ASSUMES that the polytopal 
    --complex considered is hereditary.
    n := #F;
    --For each pair of facets, take their intersection:
    intersectFacets := unique flatten apply(#F-1, i-> 
	apply(toList(i+1..#F-1), 
	    j-> sort select(F_i, 
		v-> member(v,F_j))));
    --Remove any non-maximal faces in this intersections:
    select(intersectFacets, f -> (
    	(number(intersectFacets, g-> all(f, j-> member(j,g)))) === 1
    ))
)

------------------------------------------
------------------------------------------
getCodimIFacesPolytope = method()
------------------------------------------
------------------------------------------
--Inputs: 
------------------------------------------
--F = list of faces of a polytope
--d = desired codimesion
------------------------------------------
--Outputs:
-----------------------------------------
--E = list of (interior) codim d faces
-----------------------------------------
getCodimIFacesPolytope(List,ZZ) := List => (F,d) ->(
    Fcodim := F;
    --Compute interior codime
    apply(d, i-> Fcodim = getCodim1FacesPolytope(Fcodim));
    Fcodim
    )

------------------------------------------
------------------------------------------
getCodimIFacesSimplicial = method()
------------------------------------------
------------------------------------------
--Inputs: 
------------------------------------------
--F = list of facets of a simplicial complex
--d = desired codimension
------------------------------------------
--Outputs:
-----------------------------------------
--E = list of (all) codim d faces
-----------------------------------------
getCodimIFacesSimplicial(List,ZZ) := List => (F,i) -> (
    d := getSize(F);
    unique flatten apply(F, f-> subsets(f,d-i))
    )

------------------------------------------
------------------------------------------
getCodim1Intersections = method();
------------------------------------------
------------------------------------------
--Code to Compute Codim 1 Intersections:
------------------------------------------
--Inputs: 
------------------------------------------
--F = facets of a pure simplicial complex 
--(as lists of vertices)
------------------------------------------
--Outputs:
------------------------------------------
--the codimension-1 (interior) intersections
------------------------------------------
getCodim1Intersections(List) := List => F ->(
    n := #F;
    d := #(F_0);
    --For each non-final facet, construct all codimension 1 subsets.
    codim1faces := apply(n-1, i -> subsets(F_i,d-1));
    --Check if a codimension 1 subset is contained in another facet,
    --store it as a codim 1 intersection.
    sort flatten apply(#codim1faces, i -> 
	select(codim1faces_i, 
	    s -> any(F_{i+1..n-1}, 
		f-> all(s, v-> member(v,f)))))
)

-----------------------------------------

formsList=method(Options=>{
	symbol Homogenize => true,
	symbol VariableName => getSymbol "t",
	symbol CoefficientRing => QQ
	}
    )
----------------------------------------------------
--This method returns a list of forms corresponding to codimension one faces
--------
--Input:
--V= vertex list
--E= codim 1 face list
--r= smoothness parameter
--------
--Output:
--List of forms defining input list of codimension one faces 
--raised to (r+1) power
------------------------------------------------------------

formsList(List,List,ZZ):=List=>opts->(V,E,r)->(
    --To homogenize, we append a 1 as the final coordinate of each vertex coord in list V.
    --If not homogenizing, still need 1s for computing equations
    d := #(first V);
    t := opts.VariableName;
    V = apply(V, v-> append(v,1));
    if opts.Homogenize then (
	    S := (opts.CoefficientRing)[t_0..t_d];
	    varlist := (vars S)_(append(toList(1..d),0));
	    ) else (
	    S = (opts.CoefficientRing)[t_1..t_d];
	    varlist = (vars S)|(matrix {{sub(1,S)}});
	    );
    varCol := transpose varlist;
    M := (transpose(matrix(S,V)));
    mM := numrows M;
    minorList := apply(E, e-> gens gb minors(mM,M_e|varCol));
    if any(minorList, I-> ideal I === ideal 1) then (
    	error "Some vertices on entered face are not in codimension 1 face."
	    );
    flatten apply(minorList, m -> (m_(0,0))^(r+1))
)


-----------------------------------------
-----------------------------------------
splineMatrix = method(Options => {
	symbol InputType => "ByFacets", 
	symbol CheckHereditary => false, 
	symbol Homogenize => true, 
	symbol VariableName => getSymbol "t",
	symbol CoefficientRing => QQ})
------------------------------------------
------------------------------------------

------------------------------------------
------------------------------------------
-- splineMatrix "ByFacets"
------------------------------------------
--Inputs: 
------------------------------------------
--("ByFacets")
--L = {L_0,L_1,L_2} (i.e. {V,F,E})
--r = degree of desired continuity 
--
-- OR!!!!
--
--("ByLinearForms")
--L = {L_0,L_1} (i.e. {B,L})
--r = degree of desired continuity
------------------------------------------
--Outputs:
-- BM = matrix with columns corresponding
-- to facets and linear forms separating facets.
------------------------------------------
splineMatrix(List,ZZ) := Matrix => opts -> (L,r) -> (
    --Use this if your list L = {V,F,E} contains
    --The inputs as a single list L.
    if opts.InputType === "ByFacets" then (
	splineMatrix(L_0,L_1,L_2,r)
	);
    if opts.InputType == "ByLinearForms" then (
	splineMatrix(L_0,L_1,r,InputType=>"ByLinearForms")
	)
    )

------------------------------------------
------------------------------------------
--Inputs: 
------------------------------------------
--("ByFacets")
--V = list of coordinates of vertices
--F = ordered lists of facets
--E = list of edges
--r = degree of desired continuity
------------------------------------------
--Outputs:
-- BM = matrix with columns corresponding
-- to facets and linear forms separating facets.
------------------------------------------
splineMatrix(List,List,List,ZZ) := Matrix => opts -> (V,F,E,r) -> (
    if opts.InputType === "ByFacets" then (
		if opts.CheckHereditary then (
	    	    if not isHereditary(F,E) then (
			error "Not hereditary."
			);
	    	    );
	d := # (first V);
	--Compute which facets are adjacent to each edge:
	facetEdgeH := apply(#E, e-> positions(F, f-> all(E_e,v-> member(v,f))));
	--Compute indices of interior edges, and replace edge list and 
	--facet adjacencies to only include these interior edges:
	indx := positions(facetEdgeH, i-> #i === 2);
	E = E_indx;
	facetEdgeH = facetEdgeH_indx;
	--Compute top boundary map for complex:
	BM := matrix apply(
	    facetEdgeH, i-> apply(
		#F, j-> if (
		    j === first i) then 1 else if (
		    j===last i) then -1 else 0));
	--List of forms definining interior codim one faces (raised to (r+1) power)
	flist := formsList(V,E,r);
	T := diagonalMatrix(flist);
	splineM := BM|T;
	) else if opts.InputType === "ByLinearForms" then (
	 print "Wrong inputs, put in lists of adjacent facets and linear forms and continuity r."
    	 );
    splineM
)

------------------------------------------
------------------------------------------
--Inputs: 
------------------------------------------
------------------------------------------
-- ("ByFacets")
--V = list of vertex coordinates
--F = list of facets
--r = degree of desired continuity
--
--    OR!!!!
--
--("ByLinearForms")
--B = list of adjacent facets
--L = list of ordered linear forms
--defining codim 1 faces, ordered as in B
--r = degree of desired continuity
------------------------------------------
--Outputs:
-- BM = matrix with columns corresponding
-- to facets and linear forms separating facets.
------------------------------------------
splineMatrix(List,List,ZZ) := Matrix => opts -> (V,F,r) ->(
    --Warn user if they are accidentally using ByFacets method with too few inputs.
    --This code assumes that the polytopal complex is hereditary.
    if opts.InputType === "ByFacets" then (
	if issimplicial(V,F) then(
	    E := getCodim1Intersections(F);
	    SM := splineMatrix(V,F,E,r,opts)  
	    )
	else(
	    E = getCodim1FacesPolytope(F);
	    SM = splineMatrix(V,F,E,r,opts)
	    );
	);
    --If user DOES want to define complex by regions and dual graph.
    if opts.InputType === "ByLinearForms" then (
	B := V;
	L := F;
	m := max flatten B;
	A := matrix apply(B, i-> apply(toList(0..m), j-> 
		if (j=== first i) then 1 
		else if (j===last i) then -1 
		else 0));
	D := matrix apply(#L, i-> apply(#L, j-> if i===j then L_i^(r+1) else 0));
	SM = A|D;
    );
    SM
)


------------------------------------------
------------------------------------------
splineModule = method(Options => {
	symbol InputType => "ByFacets",
	symbol CheckHereditary => false, 
	symbol Homogenize => true, 
	symbol VariableName => getSymbol "t",
	symbol CoefficientRing => QQ}
    )
------------------------------------------
------------------------------------------
-- This method computes the splineModule
-- of a complex Delta, given by either
-- facets, codim 1 faces, and vertex coors,
-- or by pairs of adjacent faces and
-- linear forms.
------------------------------------------
--Inputs: 
------------------------------------------
--V = list of vertices
--F = list of facets
--E = list of edges
--r = desired continuity of splines
------------------------------------------
--Outputs:
--Spline module S^r(Delta)
------------------------------------------
splineModule(List,List,List,ZZ) := Matrix => opts -> (V,F,E,r) -> (
    	AD := splineMatrix(V,F,E,r,opts);
	K := ker AD;
	b := #F;
    	image submatrix(gens K, toList(0..b-1),)
)

------------------------------------------
--Inputs: 
------------------------------------------
--V = list of vertices
--F = list of facets
--r = desired continuity of splines
--
--    OR!!!!
--
--V = list of pairs of adjacent faces
--F = list of linear forms defining codim 1 faces.
--r = desired continuity of splines
------------------------------------------
--Outputs:
--Spline module S^r(Delta)
------------------------------------------
splineModule(List,List,ZZ) := Matrix => opts -> (V,F,r) -> (
    	AD := splineMatrix(V,F,r,opts);
	K := ker AD;
	b := #F;
	if opts.InputType==="ByLinearForms" then (
		b = #(unique flatten V)
		);
    	image submatrix(gens K, toList(0..b-1),)
)
------------------------------------------
-------------------------------------------
-------------------------------------------
splineDimTable=method(Options => {
	symbol InputType => "ByFacets"
	}
    );
-------------------------------------------
-----Inputs:
-------------------------------------------
----- a= lower bound of dim table
----- b= upper bound of dim table
----- M= module
--------------------------------------------
------ Outputs:
--------------------------------------------
------ A net with the degrees between a and b on top row
------ and corresponding dimensions of graded pieces
------ of M in bottom row
-------------------------------------------

splineDimTable(ZZ,ZZ,Module):=Net=>opts->(a,b,M)->(
    r1:=prepend("Degree",toList(a..b));
    r2:=prepend("Dimension",apply(toList(a..b),i->hilbertFunction(i,M)));
    netList {r1,r2}
    )

-------------------------------------------
-----Inputs:
-------------------------------------------
----- a= lower bound of range
----- b= upper bound of range
----- L= list {V,F,E}, where V is a list of vertices, F a list of facets, E a list of codim 1 faces
----- r= degree of desired continuity
-------------------------------------------
-----Outputs:
-------------------------------------------
-------A table with the dimensions of the graded pieces
------ of the spline module in the range (a,b)
-------------------------------------------

splineDimTable(ZZ,ZZ,List,ZZ):= Net=>opts->(a,b,L,r)->(
    M := splineModule(L_0,L_1,L_2,r);
    splineDimTable(a,b,M)
    )

-------------------------------------------
-----Inputs:
-------------------------------------------
----- a= lower bound of range
----- b= upper bound of range
----- L= list {V,F}, where V is list of vertices, F a list of facets
-------------
-----OR!!
-------------------------------------------
----- a= lower bound of range
----- b= upper bound of range
----- L= list {V,F}, where V is a list of adjacent facets, F a list of forms
-----------defining codim 1 faces along which adjacent facets meet
-------------------------------------------
-------Outputs:
-------------------------------------------
-------A table with the dimensions of the graded pieces
------ of the spline module in the range (a,b)
-------------------------------------------

splineDimTable(ZZ,ZZ,List,ZZ):= Net => opts->(a,b,L,r)->(
    M := splineModule(L_0,L_1,r,opts);
    splineDimTable(a,b,M)
    )


-------------------------------------------
-------------------------------------------
posNum=method();
-------------------------------------------
-----Inputs:
-------------------------------------------
----- M, a graded module
--------------------------------------------
------ Outputs:
--------------------------------------------
------ The postulation number (largest integer 
------ for which Hilbert function and polynomial 
------ of M disagree).
--------------------------------------------
posNum(Module):= (N) ->(
    k := regularity N;
    while hilbertFunction(k,N)==hilbertPolyEval(k,N) do	(k=k-1);
    k
    )

------------------------------------------
-----------------------------------------

hilbertCTable=method();
-------------------------------------------
-----Inputs:
-------------------------------------------
----- a= an integer, lower bound
----- b= an integer, upper bound
----- M= graded module over a polynomial ring
--------------------------------------------
------ Outputs:
--------------------------------------------
------ A table whose top two rows are the same as
------ the output of splineDimTable and whose 
------ third row compares the first two to the
------ Hilbert Polynomial
--------------------------------------------

hilbertCTable(ZZ,ZZ,Module):= (a,b,M) ->(
    r1:=prepend("Degree",toList(a..b));
    r2:=prepend("Dimension",apply(toList(a..b),i->hilbertFunction(i,M)));
    r3:=prepend("HilbertPoly",apply(toList(a..b),i->hilbertPolyEval(i,M)));
    netList {r1,r2,r3}
    )
---------------------------------------------

hilbertPolyEval=method();
---------------------------------------------
-------------------------------------------
-----Inputs:
-------------------------------------------
----- i= integer at which you will evaluate the Hilbert polynomial
----- M= module
--------------------------------------------
------ Outputs:
--------------------------------------------
------ An Hilbert polynomial of the module M
------ evaluated at i.
--------------------------------------------

hilbertPolyEval(ZZ,Module):=(i,M)->(
    P:=hilbertPolynomial(M,Projective=>false);
    sub(P,(vars ring P)_(0,0)=>i)
    )



------------------------------------------
------------------------------------------
-- This method computes the generalized spline module
-- associated to a graph whose edges are labeled by ideals.
------------------------------------------
--Inputs: 
------------------------------------------
--E = list of edges. Each edge is a list with two vertices.
----The set of vertices must be the integers 0..n-1.
--ideals = list of ideals that label the edges. 
----Ideals must be entered in same order as corresponding edges in E.
----Note that ambient ring must already be defined so that ideals can
----be entered.
------------------------------------------
--Outputs:
------------------------------------------
--Module of generalized splines on the graph given by the edgelist.
------------------------------------------
generalizedSplines = method();
--assume vertices are 0,...,n-1
generalizedSplines(List,List) := Module => (E,ideals) ->(
    S := ring first ideals;
    vertices := unique flatten E;
    n := #vertices;
    T := directSum(apply(ideals,I->coker gens I));
--Boundary Map from Edges to vertices (this encodes spline conditions)
    M := matrix apply(E,
	e->apply(n,
	    v->if(v===first e) then 1
	    else if(v===last e) then -1
	    else 0));
   ker(map(T,S^n,sub(M,S)))
);


------------------------------------------
simpBoundary = method()
------------------------------------------
--Input:
--F = list of codim i faces
--E = list of codim i+1 faces
------------------------------------------
--Output:
--B = boundary map matrix between codim i and codim i+1 faces
------------------------------------------
--Example:
--F = {{0,1,2},{0,1,3},{1,3,4},{1,2,4},{2,4,5},{0,2,5},{0,3,5}}
--E = {{0,1},{1,2},{0,2},{3,0},{1,3},{1,4},{2,4},{2,5},{0,5},{3,4},{4,5}}
--V = {{0},{1},{2},{4}}
------------------------------------------
simpBoundary(List,List) := Matrix => (F,E) -> (
    F = apply(F, f-> sort f);
    E = apply(E, e-> sort e);
    tempLF := {};
    rowList := {};
    apply(F, f-> (
	    tempLF = hashTable apply(#f, v-> position(E,e-> e == drop(f,{v,v})) => (-1)^v);
	    rowList = append(rowList,apply(#E, j->if member(j,keys tempLF) then tempLF#j else 0));
	    )
	);
    transpose matrix rowList
    )

------------------------------------------
polyBoundary = method()
------------------------------------------
--Input:
--F = list of codim i faces of polyhedral complex
--E = list of codim i+1 faces of polyhedral complex
------------------------------------------
--Output:
--B = boundary map matrix between codim i and codim i+1 faces
------------------------------------------
--Example:
--Coming!!!
------------------------------------------
polyBoundary(List,List):=Matrix => (F,E)->(
    print("Not Implemented Yet");
    )

------------------------------------------

--Containment function for lists--
subsetL:=(L1,L2)->(
    all(L1,f->member(f,L2))
    )

boundaryComplex = method()
------------------------------------------
--Input:
--F= list of facets of a simplicial complex
----which is a pseudomanifold (Important!)
------------------------------------------
--Output:
--A list of codim one faces on the boundary
------------------------------------------
boundaryComplex(List) := List => F -> (
    n := #F;
    d := #(F_0);
    codim1faces := unique flatten apply(n,i-> subsets(F_i,d-1));
    select(codim1faces, f-> number(F, g-> all(f, v-> member(v,g))) === 1)
    )
------------------------------------------
--Input:
--PC= a polyhedral complex which is a 
--pseudomanifold (Important!)
------------------------------------------
--Output:
--A polyhedral complex which is the boundary
--of the input polyhedral complex
------------------------------------------
boundaryComplex(PolyhedralComplex):=PolyhedralComplex => PC->(
	d :=dim PC;
	Facets :=polyhedra(d,PC);
	Faces :=polyhedra(d-1,PC);
	polyhedralComplex(
		select(Faces,f->(
			vf := entries transpose Polyhedra$vertices f;
			#select(Facets,F->(
				vF := entries transpose Polyhedra$vertices F;
				subsetL(vf,vF) ))==1
			)
		    )
		)
	    )

------------------------------------------------

topologicalBoundaryComplex = method(
    	Options =>{
	    symbol InputType => "Simplicial",
	    symbol Homogenize => true, 
	    symbol VariableName => getSymbol "t",
	    symbol CoefficientRing => QQ
	    }
    )
------------------------------------------------
---This method computes the cellular chain complex of a simplicial or
---polyhedral(not implemented yet) complex with coefficients in a polynomial
---ring.
------------------------------------------------
---Inputs (if simplicial): A list of facets
------------------------------------------------
---Outputs: The cellular chain complex whose homology
--- is the homology of the simplicial complex relative
--- to its boundary.
--------------------------------------------------

topologicalBoundaryComplex(List) := ChainComplex => opts -> F -> (
    if opts.InputType === "Polyhedral" then (
	"Not implemented yet."
	);
    if opts.InputType === "Simplicial" then (
	d := (# first F);
	if opts.Homogenize then (
	    t := opts.VariableName;
	    S := (opts.CoefficientRing)[t_0..t_d];
	    varlist := (vars S)_(append(toList(1..d),0));
	    ) else (
	    t = opts.VariableName;
	    S = (opts.CoefficientRing)[t_1..t_d];
	    varlist = (vars S)|(matrix {{sub(1,S)}});
	    );
	boundaryF := boundaryComplex(F);
	C := apply(d, i-> getCodimIFacesSimplicial(F,i));
	boundaryC := join({{}},apply(d-1, i-> getCodimIFacesSimplicial(boundaryF,i)));
    	intC := apply(#C, i -> select(C_i, f -> not member(f,boundaryC_i)));
    	chainComplex(reverse apply(#intC-1, c-> simpBoundary(intC_c,intC_(c+1))))**S
	)
    )

------------------------------------------
fIdeal=method(Options=> {
	symbol InputType => "Simplicial"
	--symbol InputType => "Polyhedra"
	}
    );
------------------------------------------
----Inputs: (Simplicial Method)
----V = list of vertices
----F = list of facets
----E = a face of the complex (V,F)
----r = smoothness parameter
------------------------------------------
----Output: The ideal generated by (r+1)st
----- powers of linear forms defining interior
----- codim one faces containing E
-----------------------------------------

fIdeal(List,List,List,ZZ):=Ideal=>opts->(V,F,E,r)->(
    if opts.InputType === "Polyhedral" then (
	"Not implemented yet."
	);
    if opts.InputType === "Simplicial" then(
    codim1Int:=getCodim1Intersections(F);    
        );
)


------------------------------------------
getSize = method();
------------------------------------------
--Input: L = List of Lists
------------------------------------------
--Output: If all lists in L are same size,
-- the length of each individial list in L
------------------------------------------
getSize(List) := ZZ => L ->(
    if all(L, v-> #v == #(L_0)) then #L_0 else null
)


------------------------------------------
issimplicial = method();
------------------------------------------
-- Assumes that the inputted complex is pure
------------------------------------------
--Inputs:
-- V = vertex coordinates of Delta
-- F = list of facets of Delta
------------------------------------------
--Outputs:
--Boolean, if Delta is simplicial,
--checking that each facet is a simplex
--of the appropriate dimension.
------------------------------------------
issimplicial(List,List) := Boolean => (V,F) ->(
    n := getSize(V);
    f := getSize(F);
    if not instance(n, Nothing) and not instance(f,Nothing) and n + 1 == f then true
    else(
	if instance(n, Nothing) then print "Vertices have inconsistent dimension."
	else false
    )
)

-----------------------------------------

------------------------------------------
------------------------------------------
-- Documentation
------------------------------------------
------------------------------------------

beginDocumentation()

-- Front Page
doc ///
    Key
        AlgebraicSplines
    Headline
        a package for building splines and computing bases
    Description
        Text
            This package provides methods for computations with piecewise polynomial functions (splines) over
	    polytopal complexes.
	Text
	    @SUBSECTION "Definitions"@
	Text
	    Let $\Delta$ be a partition (simplicial,polytopal,cellular,rectilinear, etc.) of a space $\RR^n$.
	    The spline module $S_d^{r}(\Delta)$ is the module of all functions $f\in C^r(\Delta)$ such that
	    $f$ is a polynomial of degree $d$ when restricted to each face $\sigma\in\Delta$.
	Text
	
	Text
	    This package computes the @TO splineModule@ and @TO splineMatrix@ of $\Delta$, as well
	    as defining new types @TO Splines@ and @TO Spline@ that contain geometric data 
	    for $\Delta$ (if entered) and details on the associated spline module $S_d^r(\Delta)$.
        Text
            @SUBSECTION "Other acknowledgements"@
            --
            Methods in this package borrows heavily from code written by Hal Schenck
	    and Mike DiPasquale.
///

------------------------------------------
-- Data type & constructor
------------------------------------------

-- Spline Matrix Constructor
doc ///
    Key
        splineMatrix
	(splineMatrix,List,List,ZZ)
	(splineMatrix,List,List,List,ZZ)
	InputType
	CheckHereditary
	ByFacets
	ByLinearForms
    Headline
        compute matrix giving adjacent regions and continuity level
    Usage
    	S = splineMatrix(V,F,E,r)
	S = splineMatrix(B,L,r)
    Inputs
    	V:List
	    list of coordinates of vertices of Delta
	F:List
	    list of facets of Delta
	E:List
	    list of edges of Delta
	r:ZZ
	    degree of desired continuity
	InputType=>String
	    either "ByFacets", or "ByLinearForms"
	CheckHereditary=>Boolean
	    either "true" or "false", depending on if you want
	    to check if Delta is hereditary before attempting 
	    to compute splines.
    Outputs
    	S:Matrix
	  resulting spline module
    Description
        Text
	    This creates the basic spline matrix that has splines as
	    its kernel.
	Example
	    V = {{0,0},{1,0},{1,1},{-1,1},{-2,-1},{0,-1}};-- the coordinates of vertices
            F = {{0,2,1},{0,2,3},{0,3,4},{0,4,5},{0,1,5}};  -- a list of facets (pure complex)
            E = {{0,1},{0,2},{0,3},{0,4},{0,5}};   -- list of edges in graph
    	    splineMatrix(V,F,E,1)
        Text
            Alternately, spline matrices can be created directly from the
	    dual graph (with edges labeled by linear forms).  Note: This way of
	    entering data requires the ambient polynomial ring to be defined.
	Example
	    R = QQ[x,y]
	    B = {{0,1},{1,2},{2,3},{3,4},{4,0}}
	    L = {x-y,y,x,y-2*x,x+y}
	    splineMatrix(B,L,1,InputType=>"ByLinearForms")

///

doc ///
    Key
        isHereditary
	(isHereditary,List,List)
	(isHereditary,List)
    Headline
    	checks if a complex $\Delta$ is hereditary
    Usage
    	B = isHereditary(F,E)
	B = isHereditary(F)
    Inputs
    	F:List
	    list of facets of F
	E:List
	    list of codimension 1 faces of F
    Outputs
    	B:Boolean
	    returns true if F is hereditary
    Description
        Text
	    A complex $\Delta$ is hereditary if it is a pseudomanifold (all 
	    codimention 1 faces are contained in two facets), and the link of 
	    each vertex is connected.
	
	Text
	    The hereditary check can take both facets and codimension 1 faces:
	
	Example
	    F = {{1,2,3},{2,3,4},{3,4,5},{4,5,6}}
	    E = {{2,3},{3,4},{4,5},{5,6}}
	    isHereditary(F,E)
	    
	Example
	    F = {{1,2,3},{2,3,4},{3,4,5},{5,6,7}}
	    E = {{2,3},{3,4},{4,5}}
	    isHereditary(F,E)
	    
	Text
	    Alternately, if the complex is simplicial, codimension 1 faces can
	    be computed automatically.
	    
	Example
	    F = {{1,2,3},{2,3,4},{3,4,5},{4,5,6}}
	    isHereditary(F)
    SeeAlso
        splineMatrix
	
/// 

doc ///
    Key
        splineModule
	(splineModule,List,List,List,ZZ)
	(splineModule,List,List,ZZ)
    Headline
        compute the module of all splines on partition of a space
    Usage
        M = splineModule(V,F,E,r)
	M = splineModule(V,F,r)
    Inputs
        V:List
	    V = list of coordinates of vertices
	F:List
	    F = list of facets
	E:List
	    E = list of codimension 1 faces (interior or not)
	r:ZZ
	    r = desired degree of smoothness
    Outputs
        M:Module
	    M = module of splines on $\Delta$
    Description
        Text
	    This is some text.
	Example
	    V = {{0,0},{1,0},{1,1},{0,1}}
	    F = {{0,1,2},{0,2,3}}
	    E = {{0,1},{0,2},{0,3},{1,2},{2,3}}
	    splineModule(V,F,E,1)
    Caveat
        I'm not sure if this is fully documented yet.
	
	
///

doc ///
    Key
        splineDimTable
	(splineDimTable,ZZ,ZZ,Module)
	(splineDimTable,ZZ,ZZ,List,ZZ)
    Headline
        a table with the dimensions of the graded pieces of a graded module
    Usage
        T=splineDimTable(a,b,M)
	T=splineDimTable(a,b,L,r)
    Inputs
        a:ZZ
	    a= lowest degree in the table
	b:ZZ
	    b= largest degree in the table
	N:Module
	    M= graded module
	L:List
	    L= a list {V,F,E} of the vertices, faces and edges of a polyhedral complex
	r:ZZ
	    r= degree of smoothnes 

    Outputs
        T:Table
	    T= table with the dimensions of the graded pieces of M in the range a,b
    Description
        Text
	    The output table gives you the dimensions of the graded pieces
	    of the module M where the degree is between a and b. 
	Example
	    V = {{0,0},{1,0},{1,1},{0,1}}
	    F = {{0,1,2},{0,2,3}}
	    E = {{0,1},{0,2},{0,3},{1,2},{2,3}}
	    M=splineModule(V,F,E,2)
	    splineDimTable(0,8,M)
	Text
	    You may instead input the list L={V,F,E} of the vertices, faces and edges of the spline.
	Example
	    L = {V,F,E};
	    splineDimTable(0,8,L,2)
	
      
///

doc ///
    Key
        hilbertPolyEval
	(hilbertPolyEval,ZZ,Module)
    Headline
        a function to evaluate the hilbertPolynomial of a graded module at an integer
    Usage
        v = hilbertPolyEval(a,M)
    Inputs
        a:ZZ
	    a= integer at which you will evaluate the hilbertPolynomial of the graded module M
	M:Module
	    M= graded module
    Outputs
        v:ZZ
	    v= hilbertPolynomial of the graded module M evaluated at a
    Description
        Text
            For any graded module M and any integer a, you may evaluate the hilberPolynomial of M
	    at a.
	Example
	    V = {{0,0},{1,0},{1,1},{0,1}};
	    F = {{0,1,2},{0,2,3}};
	    E = {{0,1},{0,2},{0,3},{1,2},{2,3}};
	    M = splineModule(V,F,E,2)
	    hilbertPolyEval(2,M)
	    
///

doc ///
    Key
        posNum
	(posNum,Module)
    Headline
        computes the largest degree at which the hilbert function of the graded module M is not equal to the hilbertPolynomial
    Usage
        v = posNum(M)
    Inputs
        M:Module
	    M= graded module
    Outputs
        v:ZZ
	    v= largest degree at which the hilbert function of the graded module M is not equal to the hilbertPolynomial
    Description
        Text
	    This function computes the postulation number of M which is defined as the
	    largest degree at which the hilbert function of the graded module M is not equal to the hilbertPolynomial
	Example
	    V = {{0,0},{1,0},{1,1},{0,1}};
	    F = {{0,1,2},{0,2,3}};
	    E = {{0,1},{0,2},{0,3},{1,2},{2,3}};
	    M = splineModule(V,F,E,2)
	    posNum(M)
	    
///
        

doc ///
    Key
        hilbertCTable
	(hilbertCTable,ZZ,ZZ,Module)
    Headline
        a table to compare the values of the hilbertFunction and hilbertPolynomial of a graded module
    Usage
        T = hilbertCTable(a,b,M)
    Inputs
        a:ZZ
	    a= lowest degree in the  table
	b:ZZ
	    b= largest degree in the table
	M:Module
	    M= graded module
    Outputs        
	T:Table
	    T= table with the degrees and values of the hilbertFunction and hilbertPolynomial
    Description
        Text
	    The first row of the output table contains the degrees, the second row contains the 
	    values of the hilbertFunction, the third row contains the values of the hilbertPolynomial
	Example
	    V = {{0,0},{1,0},{1,1},{0,1}}
	    F = {{0,1,2},{0,2,3}}
	    E = {{0,1},{0,2},{0,3},{1,2},{2,3}}
	    hilbertCTable(0,8,splineModule(V,F,E,1))

///

doc ///
    Key
        Splines
	VertexCoordinates
	Regions
	SplineModule
    Headline
    	a class for splines (piecewise polynomial functions on subdivisions)
    Description
    	Text
	    This class is a type of @TO "HashTable"@ that stores information on
	    a subdivision $\Delta$ of ${\mathbb R}^n$, given by a set of vertex
	    coordinates and a list of facets (and possibly edges), along with a
	    module of all splines on $\Delta$ of continuity $r$.
	Example
	    V = {{0,0},{1,0},{1,1},{-1,1},{-2,-1},{0,-1}};
	    F = {{0,2,1},{0,2,3},{0,3,4},{0,4,5},{0,1,5}};
	    E = {{0,1},{0,2},{0,3},{0,4},{0,5}};
	    S = splines(V,F,E,1) -- splines in R^2 with smoothness 1
    SeeAlso
        splines
	Spline
	spline
///

TEST ///
V = {{0,0},{1,0},{1,1},{-1,1},{-2,-1},{0,-1}}
F = {{0,2,1},{0,2,3},{0,3,4},{0,4,5},{0,1,5}}
E = {{0,1},{0,2},{0,3},{0,4},{0,5}}
assert(splineMatrix(V,F,E,0) == matrix {{1, 0, 0, 0, -1, t_2, 0, 0, 0, 0}, {1, -1, 0, 0, 0, 0, t_1-t_2,
      0, 0, 0}, {0, 1, -1, 0, 0, 0, 0, t_1+t_2, 0, 0}, {0, 0, 1, -1, 0, 0, 0,
      0, t_1-2*t_2, 0}, {0, 0, 0, 1, -1, 0, 0, 0, 0, t_1}})
assert(splineMatrix(V,F,E,0,Homogenize=>false) == matrix {{1, 0, 0, 0, -1, t_2, 0, 0, 0, 0}, {1, -1, 0, 0, 0, 0, t_1-t_2,
      0, 0, 0}, {0, 1, -1, 0, 0, 0, 0, t_1+t_2, 0, 0}, {0, 0, 1, -1, 0, 0, 0,
      0, t_1-2*t_2, 0}, {0, 0, 0, 1, -1, 0, 0, 0, 0, t_1}})
assert(splineMatrix(V,F,E,1) == matrix {{1, 0, 0, 0, -1, t_2^2, 0, 0, 0, 0}, {1, -1, 0, 0, 0, 0,
      t_1^2-2*t_1*t_2+t_2^2, 0, 0, 0}, {0, 1, -1, 0, 0, 0, 0,
      t_1^2+2*t_1*t_2+t_2^2, 0, 0}, {0, 0, 1, -1, 0, 0, 0, 0,
      t_1^2-4*t_1*t_2+4*t_2^2, 0}, {0, 0, 0, 1, -1, 0, 0, 0, 0, t_1^2}})
assert(isHereditary(F,E) === true)
///

TEST ///
V={{-5,0},{-3,0},{-1,-4},{-1,4},{-1,-2},{-1,2},{0,-1},{0,1},{1,-2},{1,2},{1,-4},{1,4},{3,0},{5,0}}
F={{0, 1, 4, 2}, {0, 1, 5, 3}, {8, 10, 13, 12}, {9, 11, 13, 12}, {1, 4, 6, 7, 5}, {2, 4, 6, 8, 10}, {3, 5, 7, 9, 11}, {6, 7, 9, 12, 8}}
E={{0, 1}, {0, 2}, {0, 3}, {1, 4}, {1, 5}, {2, 4}, {2, 10}, {3, 5}, {3, 11}, {4, 6}, {5, 7}, {6, 7}, {6, 8}, {7, 9}, {8, 10}, {8, 12}, {9, 11}, {9, 12}, {10, 13}, {11, 13}, {12, 13}}
assert(splineMatrix(V,F,E,0) == matrix {{1, -1, 0, 0, 0, 0, 0, 0, t_2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0}, {1, 0, 0, 0, -1, 0, 0, 0, 0, 3*t_0+t_1+t_2, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0}, {0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 3*t_0+t_1-t_2, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, {1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0,
      t_0+t_1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, {0, 1, 0, 0, 0, 0, -1, 0, 0,
      0, 0, 0, t_0+t_1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 1, -1, 0,
      0, 0, 0, 0, 0, 0, t_0-t_1+t_2, 0, 0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0,
      1, 0, -1, 0, 0, 0, 0, 0, 0, 0, t_0-t_1-t_2, 0, 0, 0, 0, 0, 0, 0, 0}, {0,
      0, 0, 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, t_1, 0, 0, 0, 0, 0, 0, 0}, {0,
      0, 0, 0, 0, 1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, t_0+t_1+t_2, 0, 0, 0, 0, 0,
      0}, {0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, t_0+t_1-t_2, 0,
      0, 0, 0, 0}, {0, 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      t_0-t_1, 0, 0, 0, 0}, {0, 0, 1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 3*t_0-t_1+t_2, 0, 0, 0}, {0, 0, 0, 1, 0, 0, -1, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, t_0-t_1, 0, 0}, {0, 0, 0, 1, 0, 0, 0, -1, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3*t_0-t_1-t_2, 0}, {0, 0, 1, -1, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, t_2}})
assert(splineMatrix(V,F,E,0,Homogenize=>false) == matrix {{1, -1, 0, 0, 0, 0, 0, 0, t_2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0}, {1, 0, 0, 0, -1, 0, 0, 0, 0, t_1+t_2+3, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0}, {0, 1, 0, 0, -1, 0, 0, 0, 0, 0, t_1-t_2+3, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0}, {1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, t_1+1, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0}, {0, 1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, t_1+1, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 1, -1, 0, 0, 0, 0, 0, 0, 0,
      t_1-t_2-1, 0, 0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 1, 0, -1, 0, 0, 0, 0,
      0, 0, 0, t_1+t_2-1, 0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 1, 0, 0, -1, 0,
      0, 0, 0, 0, 0, 0, t_1, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 1, 0, -1, 0,
      0, 0, 0, 0, 0, 0, 0, t_1+t_2+1, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 1,
      -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, t_1-t_2+1, 0, 0, 0, 0, 0}, {0, 0, 1, 0, 0,
      -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, t_1-1, 0, 0, 0, 0}, {0, 0, 1, 0,
      0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, t_1-t_2-3, 0, 0, 0}, {0, 0,
      0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, t_1-1, 0, 0}, {0,
      0, 0, 1, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, t_1+t_2-3,
      0}, {0, 0, 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      t_2}})
assert(isHereditary(F,E) === true)
///


end

