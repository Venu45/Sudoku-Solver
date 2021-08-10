
#include<bits/stdc++.h>
#include <cuda.h>
#include<iostream>
#include <fstream>
#include<stdio.h>
#include<stdlib.h>

//#define f first
//#define s second

using namespace std;


struct eltype{
    int f;
    int rowno;
    int colno;
};

vector< vector <  struct eltype > >  g;

int find_col(vector< vector <  struct eltype > > A , int rows , int cols){
    int minind = -1;
    int min = 1000;
    int sum = 0;
    for(int ii=0;ii<cols;ii++){
        sum = 0;
        for(int jj=0;jj<rows;jj++){
            if(A[jj][ii].f == 1 ){
                sum = sum + 1;
            }
        }
        if(sum<min){
            min = sum;
            minind = ii;
        }
    }
    if(min==0)return -1;
    return minind;
}

vector< vector <  struct eltype > > delcol( vector< vector <  struct eltype > > v , int j ){
    // delete j indexed coloumn
    for(int ii=0;ii<v.size();ii++){
        v[ii].erase(v[ii].begin()+j);
    }
    return v;
}

vector< vector <  struct eltype > > help_algox(vector< vector <  struct eltype > > A , int rows , int cols  ,  int r){
    vector<int> x;
    //cout<<"cols selected"<<endl;
    for(int ii=0;ii<A[0].size();ii++){
        if(A[r][ii].f == 1){
            x.push_back(ii);
            //cout<<ii<<" ";
        }
    }
    //cout<<endl;
    for(int ii=x.size()-1;ii>=0;ii--){
        for(int kk=A.size()-1;kk>=0;kk--){
            if(A[kk][x[ii]].f == 1){
                // delete kk row
                A.erase(A.begin()+kk);
                //cout<<" row "<<kk<<" deleted"<<endl;
                //print2(A);
            }
        }
        // delete coloumn ii

        A = delcol(A,x[ii]);

        //cout<<"col "<<x[ii]<<" deleted"<<endl;
        //print2(A);
    }
    //vector< vector <  pair< int , pair <int , int> > > > soln;

    return A;

    //if(A.size() == 0) return partsoln;
    //return algX(A,A.size(),A[0].size(),partsoln);
}


vector< vector <  struct eltype > > algX ( vector< vector < struct eltype > > A,int rows ,int cols ,vector< vector <  struct eltype > > partsoln){
    if(cols==0){
        //cout<<" ending"<<endl;
        return partsoln;
    }

    vector< vector <  struct eltype > > soln2;

    //cout<<"partsoln size is : "<<partsoln.size()<<endl;

    //cout<<"in algx  cols are : "<<cols <<endl;
    
    // choose the coloumn with min no of 1's in it

    int c = find_col(A,rows,cols); // c is our chosen coloumn index

    if(c==-1) return soln2;

    //cout<<"selected colomn is :"<<c<<endl;

    vector<int> r;

    for(int ii=0;ii<rows;ii++){
        if(A[ii][c].f == 1){
            r.push_back(ii);
        }
    }

    vector< vector <  struct eltype > > temp1; // for copy of A
    vector< vector <  struct eltype > > temp2 ; // for copy of partsoln
    vector< vector <  struct eltype > > soln;
    vector< vector <  struct eltype > > soln1;

    //cout<<"check"<<endl;
    //cout<<r.size()<<endl;

    int useg,llpr,ttpr,rwno;

    for(int jj=0;jj<r.size();jj++){
        // call each branch
        //cout<<"each branch"<<endl;
        //cout<<"slected row is :"<<r[jj]<<endl;
        temp1 = A;
        temp2 = partsoln;
        //temp2.push_back(A[r[jj]]);
        useg = ((A[r[jj]][0]).rowno) ;
        llpr = useg/100;
        ttpr = useg%100;
        rwno = (ttpr-1)*9 + llpr-1;

        temp2.push_back(g[rwno]);
        soln = help_algox(temp1,rows,cols,r[jj]);
        //cout<<"hello"<<endl;
        //print2(soln);
        if(soln.size() == 0) { 
            //cout<<"part soln is "<<endl;
            //print2(partsoln); 
            return temp2;
        }

        soln1 =  algX(soln,soln.size() , soln[0].size() , temp2 );

        if(soln1.size() != 0) return soln1;
    }

    return soln2;

}

__global__ void kernel1(struct eltype * gpug){
    int yy = blockIdx.x;
    int ii = yy/9;
    int jj = yy%9+1;
    int kk = threadIdx.x + 1;
    gpug[ ( 9*ii+(jj-1) ) * 324 + kk - 1 ].f = 0;
    gpug[ ( 9*ii+(jj-1) ) * 324 + kk - 1 ].rowno = 1+ii+100*jj;
    gpug[ ( 9*ii+(jj-1) ) * 324 + kk - 1 ].colno = kk;
}

__global__ void kernel2(struct eltype * gpug){
    int ii = blockIdx.x;
    int jj = threadIdx.x+1;
    gpug[(9*ii+(jj-1))*324 + ii].f =1; 
    gpug[ (9*ii+(jj-1))*324 + 80+jj+(ii/9)*9  ].f = 1;
    gpug[ (9*ii+(jj-1))*324 + 161+jj+(ii%9)*9  ].f = 1;
    gpug[ (9*ii+(jj-1))*324 +  242+jj+(ii/27)*27 + ((ii/3)%3)*9 ].f = 1;
}

__global__ void kernel3(int * a ){
    int id = threadIdx.x;
    a[id]=0;
}

__global__ void kernel4(struct eltype * gpug , int * a , int * b){
    // m is ecover gpu copy which is g
    // a is gpurow
    // b is gpucol
    int ii = blockIdx.x;
    int jj = threadIdx.x;
    if(b[jj] ==1 && gpug[ii*324+jj].f == 1){
        a[ii]=1;
    }
}




int main(){
    
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    float milliseconds = 0;
    cudaEventRecord(start,0);

    struct eltype * ecover ;
    ecover = (struct eltype * )malloc (729 * 324 * sizeof(struct eltype)) ;

    struct eltype * gpug;
    cudaMalloc(&gpug , 729 * 324 * sizeof(struct eltype));

    //struct eltype * gpuexactcover;
    //cudaMalloc(&gpuexactcover , 729 * 324 * sizeof(struct eltype));

    

    

    kernel1<<< 729 , 324 >>> (gpug) ;
    cudaDeviceSynchronize();
    cudaMemcpy(ecover , gpug , 729 * 324 * sizeof(struct eltype) , cudaMemcpyDeviceToHost);


    
    // this can be done by one kernel2 81 X 9 launch
    

    kernel2<<< 81 , 9 >>> (gpug);
    cudaDeviceSynchronize();
    cudaMemcpy(ecover , gpug , 729 * 324 * sizeof(struct eltype) , cudaMemcpyDeviceToHost);
    //int ch=0;
    //for(int ii=0;ii<729;ii++){
        //ch=0;
        //for(int jj=0;jj<324;jj++){
            //if(ecover[ii*324+jj].f == 1)ch++;
        //}
        //cout<<ch<<" ";
    //}
    //cout<<endl;
    // copy ecover to g
    // gpug is used to push a row into partsoln

    //cout<<"kernel2 done "<<endl;
    
    //cudaMemcpy( gpug , exactcover , 729 * 324 * sizeof(struct eltype) , cudaMemcpyHostToDevice )
    // gpug is used to push a row into partsoln

    int * sudoku ;
    sudoku = (int *) malloc (9 * 9 * sizeof(int));

    ifstream fin;
    fin.open("input.txt");
    int cell;

    int pos[82];int * gpupos;
    cudaMalloc(&gpupos,82*sizeof(int));
    kernel3 <<< 1,82 >>>(gpupos);
    cudaDeviceSynchronize();
    cudaMemcpy(pos,gpupos , 82*sizeof(int) ,cudaMemcpyDeviceToHost );
    
    int row[729];int * gpurow;
    cudaMalloc(&gpurow,729*sizeof(int));
    kernel3 <<< 1,729 >>>(gpurow);
    cudaDeviceSynchronize();
    cudaMemcpy(row,gpurow , 729*sizeof(int) ,cudaMemcpyDeviceToHost );

    int col[324];int * gpucol;
    cudaMalloc(&gpucol,324*sizeof(int));
    kernel3 <<< 1,324 >>>(gpucol);
    cudaDeviceSynchronize();
    cudaMemcpy(col,gpucol , 324*sizeof(int) ,cudaMemcpyDeviceToHost );

    //for(int ii=0;ii<729;ii++){
        //cout<<row[ii]<<" ";
    //}
    //cout<<endl;
    //for(int ii=0;ii<324;ii++){
        //col[ii]=0;
    //} 
    //for(int ii=0;ii<82;ii++){
        //pos[ii]=0;
   // }

    vector<int> delrows; // vector containing indexes of rows to delete
    vector<int> delcols; // vector containing indexes of cols to delete
    for(int ii=0;ii<9;ii++){
        for(int jj=0;jj<9;jj++){
            fin>>cell;
            sudoku[ii*9 + jj] = cell;
            if(cell!=0){
                pos[ii*9 + jj + 1]=1;
                //row[(ii*9 + jj )*9 ]=1;
                //for(int kk=0;kk<9;kk++){
                    //row[(ii*9 + jj )*9 + kk ]=1;
                    //delrows.push_back((ii*9 + jj )*9 + kk);
                //}
                // ii above is ii*9+jj
                // jj above is cell
                col[ii*9 + jj]=1;
                col[80+cell+((ii*9+jj)/9)*9]=1;
                col[161+cell+((ii*9+jj)%9)*9]=1;
                col[242+cell+((ii*9+jj)/27)*27 + (((ii*9+jj)/3)%3)*9]=1;
                //delrows.push_back()
            }
        }
    }

    

    cudaMemcpy(gpucol , col , 324*sizeof(int) , cudaMemcpyHostToDevice);
    cudaMemcpy(gpurow , row , 729*sizeof(int) , cudaMemcpyHostToDevice);
    cudaMemcpy(gpug , ecover , 729*324*sizeof(struct eltype) , cudaMemcpyHostToDevice);
    

    kernel4<<<729 , 324 >>> (gpug , gpurow , gpucol);
    cudaDeviceSynchronize();
    cudaMemcpy(row,gpurow , 729*sizeof(int) ,cudaMemcpyDeviceToHost );

    

    for(int ii=0;ii<324;ii++){
        //cout<<col[ii]<<" ";
        if(col[ii]==1){
            delcols.push_back(ii);
        }
    }
    //cout<<endl;
    

    vector <  struct eltype > temp45;

    vector< vector <  struct eltype > > exactcover ; // exact cover matrix of input sudoku

    int check =0;
    for(int ii=0;ii<729;ii++){
        exactcover.push_back(temp45);
        
    }
    for(int ii=0;ii<729;ii++){
        //check=0;
        for(int jj=0;jj<324;jj++){
            exactcover[ii].push_back(ecover[ii*324 + jj]);
            //if( jj <81 && exactcover[ii][jj].f==1)check++;
        }
        //cout<<check<<" ";
    }
    //cout<<endl;
    g = exactcover;
    cout<<exactcover[0].size()<<endl;

    
    

    for(int ii=0;ii<729;ii++){
        if(row[ii]==1){
            delrows.push_back(ii);
        }
    }

    cout<<delrows.size()<<" "<<delcols.size()<<endl;

    for(int ii=delrows.size()-1;ii>=0 ;ii--){
        exactcover.erase(exactcover.begin() + delrows[ii]);
    }

    for(int ii=delcols.size()-1;ii>=0;ii--){
        exactcover = delcol(exactcover , delcols[ii]);
    }
    cout<<exactcover.size()<<" ";
    cout<<exactcover[0].size()<<endl;

    



    vector< vector <  struct eltype > > empty;
    vector< vector <  struct eltype > > soln = algX(exactcover , exactcover.size() , exactcover[0].size() , empty);

    cout<<"soln is"<<endl;
    cout<<soln.size()<<endl;

    

    // one kernel can write into sudoku using soln
    int sdk,bdk,cdk,edk,fdk;
    for(int ii=0;ii<soln.size();ii++){
        for(int jj=0;jj<81;jj++){
            if(soln[ii][jj].f == 1){
                //cout<<ii<<" "<<jj<<endl;
                // add an element 
                sdk = (soln[ii][jj].rowno) ; // row no as stored in exact cover matrix
                sdk = sdk-1;
                bdk = sdk/100; // the no to put
                cdk = sdk%100;
                edk = cdk/9; // row index of sudoku
                fdk = cdk%9; // col index of sudoku
                sudoku[edk*9+fdk]=bdk;
                //cout<<edk<<" "<<fdk<<" "<<bdk<<endl;
            }
        }
    }

    for(int ii=0;ii<9;ii++){
        for(int jj=0;jj<9;jj++){
            cout<<sudoku[ii*9+jj]<<" ";
        }
        cout<<endl;
    }
    //print2d(sudoku);

    fin.close();

    cudaEventRecord(stop,0);
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&milliseconds, start, stop);
    printf("Time taken by function to execute is: %.6f ms\n", milliseconds);
    return 0;
}