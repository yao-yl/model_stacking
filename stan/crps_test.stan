functions {

  
  real CRPS_pointwise(int K, vector mean_bias, matrix entropy, vector w) { 

//    dim(predict_sample)=c(S, K), prediction for a fixed point y from all models
// 	  y: real
// 	  w: simplex weight
// 	  mean_bias and entropy 
  	real entropy_aggregrate = 0;
  	for (k1 in 1:K)
  		for (k2 in 1:K)
  			entropy_aggregrate=entropy_aggregrate+entropy[k1, k2] * w[k1] * w[k2];
  			
  	return( dot_product(mean_bias, w) - 0.5 * entropy_aggregrate );
  }
}


data {
  int<lower = 0> K; // number of models
  int<lower = 1> T; // number of time points to score
  int<lower = 1> S; // number of predictive samples for every true value
  int<lower = 1> R; // number of regions
  
  matrix[S, K] predict_sample_mat[T, R]; 
  vector[T] y[R];
}

transformed data {
  
  vector[K] mean_bias[T,R]; // pre-calculate array of all mean_bias values
  matrix[S, S] entropy[T, R];
  
  vector[T] lambda; // weight different time points differently
  vector[R] gamma; // maybe weight different regions differently
  
  // mean bias calculation
  for (r in 1:R) {
    for (t in 1:T) {
      for (k in 1:K) {
        // place_holder for now. 
        mean_bias[t, r, k] = 1;
      }
    }
  }

  // entropy matrix calculation
  for (r in 1:R) {
    for (t in 1:T) {
      
      // compute individual entropy matrices for one time point in one region
      for( k1 in 1:K){
	    	for(k2 in 1:k1)
		    	for(s1 in 1:S)
	    			for(s2 in 1:S)
		    			entropy[t, r, k1, k2] = entropy[t, r, k1, k2] + 
		    			                        1.0/S^2 * fabs( predict_sample_mat[t, r, s1, k1] - predict_sample_mat[t, r, s2, k2]);
	    	
	    	for(k2 in (k1+1):K)	
		    	entropy[t, r, k1, k2]=entropy[t, r, k2, k1];
	    
	    }
    }
  }	
  	
	
  // time point weights
  for (t in 1:T) {
    lambda[t] = 1.5 - (1 - (t + 0.0) /T)^2;
  }
  
  // region weights
  for (r in 1:R) {
    gamma[r] = 1.0 / R;
  }
}

parameters {
  simplex[K] weights;
  
  // maybe at some later point add parameters alpha and beta. 
  // alpha is a parameter that can correct the mean by adding a constant 
  // value and beta is a parameter to expand or contract the predictive
  // samples to get optimal uncertainty. 
}


model {
	for(t in 1:T)
	  for (r in 1:R) 
		 target += lambda[t] * 	gamma[r] * CRPS_pointwise(K, mean_bias[t,r], entropy[t,r], weights);
	
	weights ~ dirichlet(rep_vector(1.01, K));
  
}