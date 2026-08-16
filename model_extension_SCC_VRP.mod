# ==============================================================================
# SHARED CUSTOMER COLLABORATION VEHICLE ROUTING PROBLEM (SCC-VRP)
# Extended with Heterogeneous Depots, Customer/Depot Transshipments, 
# Departure/Arrival Times, and Waiting Times
# ==============================================================================
# ------------------------------------------------------------------------------#
# 1. SETS & CORE INDEXING
# ------------------------------------------------------------------------------#
set N ordered;              # Customer set {1, ..., n}
set C ordered;              # Carriers {1,...,m}
set K{r in C} ordered;      # Set of available vehicle routes/vehicles for carrier r

param d{i in N, r in C};    # Demand of customer i associated with carrier r

set Ci{i in N} ordered := {r in C: d[i,r] > 0}; # Carriers for which customer i has demand
set Nr{r in C} ordered := {i in N: d[i,r] > 0}; # Customers having demand for carrier r

set o ordered;             # Set of carrier depots {o1, ..., om}

set V ordered = o union N; # Complete node set (ALL depots + customers)
set A := V cross V; 

# Visitable nodes for carrier r: dedicated customers + ALL carrier depots
set Vr{r in C} := Nr[r] union o;

# Feasible directed arcs for carrier r:
#   - Baseline: internal arcs between depot o_r and own customers, and among own customers
#   - Transshipment extension: carrier r may visit external depots (o_s, s != r)
#     to drop off/pick up transferred customer orders
set Ar{r in C} :=
   {i in Vr[r], j in Vr[r]:
           
            (i in Nr[r] and j in Nr[r])                              
         or (i = member(r,o) and j in Nr[r])                         
         or (i in Nr[r] and j = member(r,o))                         

            
         or (i = member(r,o) and j in (o diff {member(r,o)}))        
         or (i in (o diff {member(r,o)}) and j = member(r,o))        
         or (i in Nr[r] and j in (o diff {member(r,o)}))             
         or (i in (o diff {member(r,o)}) and j in Nr[r])             
   };

set depts{r in C} :=
   {i in {member(r,o)}, j in {member(r,o)}: i = member(r,o) and j = member(r,o)};

set NodesCheck{r in C} ordered := Vr[r] diff {member(r,o)};
param n_check{r in C} := card(NodesCheck[r]);
set index_Check{r in C} ordered := {1..((2**(n_check[r]))-1)};
set POW_Check{r in C, w in index_Check[r]} ordered :=
   {i in NodesCheck[r]: (w div 2**(ord(i, NodesCheck[r]) - 1)) mod 2 = 1};   

param v := card(V);
set index_V ordered :=  {1..((2**(v))-1)};
set POW_V{w in index_V} ordered :=
   {i in V: (w div 2**(ord(i) - 1)) mod 2 = 1};


# ------------------------------------------------------------------------------#
# 2. PROBLEM PARAMETERS
# ------------------------------------------------------------------------------#
param m := card(C);						  # Total number of carriers
param Q;                                  # Vehicle capacity (homogeneous fleet, the same for all carriers)
param dist{i in V, j in V};               # Distance matrix
param trav_time{i in V, j in V};          # Asymmetric travel time matrix
param BIGT := sum{r in C, k in K[r], (i,j) in Ar[r]} trav_time[i,j]; # Big-M upper bound for time-window and linearization constraints

#------------------------------------------#
# 3. DECISION VARIABLES
#------------------------------------------#

# Routing & Demand Allocation
var X{r in C, (i,j) in (Ar[r] union depts[r]), k in K[r]} binary;
var Z{r in C, i in Nr[r], s in Ci[i], k in K[s]} binary;

# Departure time of vehicle (r, k) from node i
var t{r in C, i in Vr[r], k in K[r]} >= 0;
# Arrival time of vehicle (r, k) at node j
var t_arr{r in C, j in Vr[r], k in K[r]} >= 0;

# Maximum service time
var W >= 0;
# Minimum service time (Minimum departure time across visited nodes)
var H >= 0;

# ------------------------------------------------------------------------------#
# 4.TRANSSHIPMENT STRUCTURES & VARIABLES
# ------------------------------------------------------------------------------#
# # Shared customers (customers having demands for both carrier r and carrier s)
set Common{r in C, s in C} :=
   {j in N : (d[j,r] > 0) and (d[j,s] > 0)};

var y{r in C, k in K[r], j in Nr[r]} binary; # = 1 if vehicle (r, k) loads/receives transferred products at customer node j

var u{s in C, k in K[s], j in Nr[s]} binary; # = 1 if vehicle (s, k) unloads/delivers products to be transferred at node j

var tp{r in C, s in C diff {r}, i in (Nr[r] inter Nr[s]), k_s in K[s], k_r in K[r], j in (Common[r,s] diff {i})} binary;
# # = 1 if demand d[i,r] is transferred at shared customer node j from vehicle (r, k_r) to vehicle (s, k_s)

var tpd{r in C, s in C diff {r}, i in (Nr[r] inter Nr[s]), k_s in K[s], k_r in K[r]} binary; 
   # = 1 if demand d[i,r] is served by carrier (s, k_s) via transshipment at depot o_s,
   #   delivered to o_s by vehicle (r, k_r)

#------------------------------------------#
# 5. OBJECTIVE FUNCTIONS
#------------------------------------------#
# 1: Total Distance Minimization
# minimize Cost: sum{r in C, k in K[r], (i,j) in Ar[r]} dist[i,j]*X[r,i,j,k];

# 2: Carrier Workload Equity 
# minimize Cost: W - H;

# 3: Makespan Minimization
minimize Cost: W;

# 4: Efficiency (Minimizing cumulative customer waiting times)
# minimize Cost: sum{r in C, j in Vr[r] diff {member(r,o)}, k in K[r]} (t[r,j,k] - t_arr[r,j,k]);
#-----------------------------------------------------------#
# 6. MODIFICATION OF THE ORIGINAL SCC-VRP CONSTRAINTS
#-----------------------------------------------------------#

subject to Allocate_Demands {i in N, r in Ci[i]}:
   sum{s in Ci[i], k in K[s]} Z[r,i,s,k] = 1;
	
subject to FlowBalance_AllNodes {r in C, k in K[r], i in Vr[r]}:
   sum{j in Vr[r] : (j,i) in Ar[r]} X[r,j,i,k] = sum{j in Vr[r] : (i,j) in Ar[r]} X[r,i,j,k];

subject to Max_One_Route {r in C, k in K[r]}:
   sum{j in Vr[r] diff {member(r,o)} : (member(r,o), j) in Ar[r]} X[r, member(r,o), j, k] <= 1;

subject to Subtour_Elimination {r in C, k in K[r], w in index_Check[r]: card(POW_Check[r,w]) >= 2}:
   sum{i in POW_Check[r,w], j in POW_Check[r,w] : (i,j) in Ar[r]} X[r,i,j,k] <= card(POW_Check[r,w]) - 1;
	
subject to Relate_X_with_Z {r in C, s in C, k in K[r], w in index_Check[r], i in (POW_Check[r,w] inter Nr[s])}:
   sum{j1 in POW_Check[r,w], j2 in Vr[r] diff POW_Check[r,w] : (j1,j2) in Ar[r]} X[r,j1,j2,k] >= Z[s,i,r,k];

subject to Vehicle_Capacity {r in C, k in K[r]}:   
   sum{i in Nr[r], s in Ci[i]} d[i,s] * Z[s,i,r,k] 
   + sum{s in C diff {r}, i in (Nr[r] inter Nr[s]), k_s in K[s]} d[i,r] * tpd[r,s,i,k_s,k]
   + sum{s in C diff {r}, i in (Nr[r] inter Nr[s]), k_s in K[s], j in (Common[r,s] diff {i})} d[i,r] * tp[r,s,i,k_s,k,j]
   <= Q;
   
#----------------------------------------------------------#
# 7. TRANSSHIPMENT CONSTRAINTS (SHARED CUSTOMER LOCATIONS)
#----------------------------------------------------------#
subject to U_bounds {s in C, k in K[s], j in Nr[s]}:
   u[s,k,j] <= sum{h in Vr[s] : (h,j) in Ar[s]} X[s,h,j,k];

subject to Y_bounds {r in C, k in K[r], j in Nr[r]}:
   y[r,k,j] <= sum{h in Vr[r] : (h,j) in Ar[r]} X[r,h,j,k];

subject to PickOneTransfer {r in C, s in C diff {r}, i in (Nr[r] inter Nr[s]), k_s in K[s]}:
	sum{k_r in K[r], j in (Common[r,s] diff {i})} tp[r,s,i,k_s,k_r,j] + sum{k_r in K[r]} tpd[r,s,i,k_s,k_r] = Z[r,i,s,k_s];

subject to TP_implies_unload {r in C, s in C diff {r}, i in (Nr[r] inter Nr[s]), k_s in K[s], k_r in K[r], j in (Common[r,s] diff {i})}:
   tp[r,s,i,k_s,k_r,j] <= u[r,k_r,j];

subject to TP_implies_load {r in C, s in C diff {r}, i in (Nr[r] inter Nr[s]), k_s in K[s], k_r in K[r], j in (Common[r,s] diff {i})}:
   tp[r,s,i,k_s,k_r,j] <= y[s,k_s,j];    

subject to Y_upper_by_causes {s in C, k in K[s], j in Nr[s]}:
   y[s,k,j] <= sum{r in C diff {s}, i in (Nr[r] inter Nr[s]), k_r in K[r] : j in (Common[r,s] diff {i})} tp[r,s,i,k,k_r,j]; 
#-----------------------------------------------------------------------#
# 8. DEPOT TRANSSHIPMENT CONSTRAINTS (EXTERNAL DEPOT o_s)
#-----------------------------------------------------------------------#
subject to TPD_forces_Visit {r in C, s in C diff {r}, i in (Nr[r] inter Nr[s]), k_s in K[s], k_r in K[r]}:
  tpd[r,s,i,k_s,k_r] <= sum{h in Vr[r] : (h, member(s,o)) in Ar[r]} X[r,h,member(s,o),k_r];

subject to Visit_forces_TPD {r in C, s in C diff {r}, k_r in K[r]}:
   sum{h in Vr[r] : (h, member(s,o)) in Ar[r]} X[r,h,member(s,o),k_r] <= sum{i in (Nr[r] inter Nr[s]), k_s in K[s]} tpd[r,s,i,k_s,k_r];         
#---------------------------------------------------------#
# 9. TEMPORAL SYNCHRONIZATION & PRECEDENCE CONSTRAINTS
#---------------------------------------------------------#
subject to Time_Propagation {r in C, k in K[r], i in Vr[r], j in Vr[r] : (i,j) in Ar[r]}:
    t_arr[r,j,k] >= t[r,i,k] + trav_time[i,j] - BIGT * (1 - X[r,i,j,k]);

subject to Calc_Departure_Time {r in C, k in K[r], j in Vr[r] diff {member(r,o)}}:
   t[r,j,k] >= t_arr[r,j,k];

subject to TimeUpper_IfNotVisited {r in C, k in K[r], j in Vr[r]}:
    t[r,j,k] <= BIGT * sum{h in Vr[r] : (h,j) in Ar[r]} X[r,h,j,k];   

subject to TArrUpper_IfNotVisited {r in C, k in K[r], j in Vr[r]}:
    t_arr[r,j,k] <= BIGT * sum{h in Vr[r] : (h,j) in Ar[r]} X[r,h,j,k];

subject to Precedence_TP {r in C, s in C diff {r}, i in (Nr[r] inter Nr[s]), k_s in K[s], k_r in K[r], j in (Common[r,s] diff {i})}:
    t[s,j,k_s] >= t_arr[r,j,k_r] - BIGT*(1 - tp[r,s,i,k_s,k_r,j]);

subject to Precedence_TPD {r in C, s in C diff {r}, i in (Nr[r] inter Nr[s]), k_s in K[s], k_r in K[r]}:
    t[s, member(s,o), k_s] >= t_arr[r, member(s,o), k_r] - BIGT*(1 - tpd[r,s,i,k_s,k_r]);
     
subject to TP_before_service {r in C, s in C diff {r}, i in (Nr[r] inter Nr[s]), k_s in K[s], k_r in K[r],
 j in (Common[r,s] diff {i})}: t_arr[s,i,k_s] >= t[s,j,k_s] - BIGT*(1 - tp[r,s,i,k_s,k_r,j]);    

subject to TPD_before_service {r in C, s in C diff {r}, i in (Nr[r] inter Nr[s]), k_s in K[s], k_r in K[r]}:
    t_arr[s,i,k_s] >= t[s, member(s,o), k_s] - BIGT*(1 - tpd[r,s,i,k_s,k_r]);

subject to auxmax{r in C, j in Vr[r] diff {member(r,o)}, k in K[r]}:
   W - t[r,j,k] >= 0;

subject to Aux_W_Max_Return {r in C, k in K[r]}:
   W >= t_arr[r, member(r,o), k];
   
subject to auxmin {r in C, j in Vr[r] diff {member(r,o)}, k in K[r]}:
   t[r,j,k] + BIGT * (1 - sum{h in Vr[r] : (h,j) in Ar[r]} X[r,h,j,k]) >= H;
      
#---------------------------------------------------------#
# 10. INTEGRITY CONSTRAINT
#---------------------------------------------------------#
subject to NoSelfLoops {r in C, k in K[r], i in Vr[r] : (i,i) in (Ar[r] union depts[r])}:
   X[r,i,i,k] = 0;      
     