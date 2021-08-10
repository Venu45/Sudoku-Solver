
// sudoku solver sequential execution , using algorithm x , exact cover

#include<bits/stdc++.h>
#include<cuda.h>
#include <algorithm>
#include <chrono>
#include<iostream>
#include <fstream>
#include<stdio.h>
#include<stdlib.h>

#define f first
#define s second

using namespace std;
//using namespace std::chrono;

vector< vector <  pair< int , pair <int , int> > > >  g;

void print1d(vector<int> v){
    for(int ii=0;ii<v.size();ii++){
        cout<<v[ii]<<" ";
    }
    cout<<endl;
}

void print2d(vector < vector < int> >v){
    for(int ii=0;ii<v.size();ii++){
        for(int jj=0;jj<v[ii].size();jj++){
            cout<<v[ii][jj]<<" ";
        }
        cout<<endl;
    }
}

void print2(vector< vector <  pair< int , pair <int , int> > > > v){
    if(v.size()==0)return;
    cout<<"   ";
    for(int jj=0;jj<v[0].size();jj++){
        cout<<(v[0][jj].s).s<<"  ";
    }
    cout<<endl;
    for(int ii=0;ii<v.size();ii++){
        cout<<(v[ii][0].s).f<<"  ";
        for(int jj=0;jj<v[ii].size();jj++){
            cout<<v[ii][jj].f<<"  ";
        }
        cout<<endl;
    }
    cout<<endl;
}

int find_col(vector< vector <  pair< int , pair <int , int> > > > A , int rows , int cols){
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

vector< vector <  pair< int , pair <int , int> > > > delcol( vector< vector <  pair< int , pair <int , int> > > > v , int j ){
    // delete j indexed coloumn
    for(int ii=0;ii<v.size();ii++){
        v[ii].erase(v[ii].begin()+j);
    }
    return v;
}

/*
If the matrix A has no columns, the current partial solution is a valid solution; terminate successfully.
Otherwise choose a column c (deterministically).
Choose a row r such that Ar, c = 1 (nondeterministically).
Include row r in the partial solution.
For each column j such that Ar, j = 1,
    for each row i such that Ai, j = 1,
        delete row i from matrix A.
    delete column j from matrix A.
Repeat this algorithm recursively on the reduced matrix A.
 */

vector< vector <  pair< int , pair <int , int> > > > help_algox(vector< vector <  pair< int , pair <int , int> > > > A , int rows , int cols  , vector< vector <  pair< int , pair <int , int> > > > partsoln , int r){
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


vector< vector <  pair< int , pair <int , int> > > > algX ( vector< vector <  pair< int , pair <int , int> > > > A , int rows , int cols  , vector< vector <  pair< int , pair <int , int> > > > partsoln ){
    if(cols==0){
        //cout<<" ending"<<endl;
        return partsoln;
    }

    vector< vector <  pair< int , pair <int , int> > > > soln2;

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

    vector< vector <  pair< int , pair <int , int> > > > temp1; // for copy of A
    vector< vector <  pair< int , pair <int , int> > > > temp2 ; // for copy of partsoln
    vector< vector <  pair< int , pair <int , int> > > > soln;
    vector< vector <  pair< int , pair <int , int> > > > soln1;

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
        useg = ((A[r[jj]][0]).s).f ;
        llpr = useg/100;
        ttpr = useg%100;
        rwno = (ttpr-1)*9 + llpr-1;

        temp2.push_back(g[rwno]);
        soln = help_algox(temp1,rows,cols,temp2,r[jj]);
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



int main(){

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    float milliseconds = 0;
    cudaEventRecord(start,0);
    

    //vector< vector <  pair< int , pair <int , int> > > > temp;

    //auto start = chrono::high_resolution_clock::now();

    vector <  pair< int , pair <int , int> > > temp;

    vector< vector <  pair< int , pair <int , int> > > > exactcover ; // exact cover matrix of input sudoku

    for(int ii=0;ii<729;ii++){
        exactcover.push_back(temp);
    }
    // exact cover has 729 rows
    for(int ii=0;ii<81;ii++){
        for(int jj=1;jj<=9;jj++){
            for(int kk=1;kk<=324;kk++){
                exactcover[9*ii+(jj-1)].push_back(make_pair( 0 , make_pair( 1+ii+100*jj , kk) ) );
            }
        }
    }
    //print2(exactcover);

    for(int ii=0;ii<81;ii++){
        //cout<<"row number is :"<<ii<<endl;
        for(int jj=1;jj<=9;jj++){
            // through all 729 rows keep 41's in each row
            exactcover[9*ii+(jj-1)][ii].f = 1;
            exactcover[9*ii+(jj-1)][80+jj+(ii/9)*9].f = 1;
            //cout<<80+jj+(ii/9)*9<<" ";
            exactcover[9*ii+(jj-1)][161+jj+(ii%9)*9].f = 1;
            //cout<<161+jj+(ii%9)*9<<" ";
            exactcover[9*ii+(jj-1)][242+jj+(ii/27)*27 + ((ii/3)%3)*9].f = 1;
            //cout<<"row number is :"<<ii<<endl;
            //cout<< 242+jj+(ii/27)*27 + ((ii/3)%3)*9<<" ";
        }
        //cout<<endl;
    }

    g = exactcover;
    //print2(exactcover);

    ofstream fout;
    ifstream fin;
    int cell;
    vector< vector <int> > sudoku;
    vector <int> p;
    for(int ii=0;ii<9;ii++){
        sudoku.push_back(p);
    }
    fin.open("input.txt");
    //fout.open("output.txt");
    int pos[82];
    int row[729];
    int col[324];
    for(int ii=0;ii<729;ii++){
        row[ii]=0;
    }
    for(int ii=0;ii<324;ii++){
        col[ii]=0;
    } 
    for(int ii=0;ii<82;ii++){
        pos[ii]=0;
    }
    vector<int> delrows; // vector containing indexes of rows to delete
    vector<int> delcols; // vector containing indexes of cols to delete
    for(int ii=0;ii<9;ii++){
        for(int jj=0;jj<9;jj++){
            fin>>cell;
            sudoku[ii].push_back(cell);
            if(cell!=0){
                pos[ii*9 + jj + 1]=1;
                //row[(ii*9 + jj )*9 ]=1;
                /*for(int kk=0;kk<9;kk++){
                    row[(ii*9 + jj )*9 + kk ]=1;
                    //delrows.push_back((ii*9 + jj )*9 + kk);
                }*/
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

    for(int ii=0;ii<324;ii++){
        if(col[ii]==1){
            delcols.push_back(ii);
        }
    }
    for(int ii=0;ii<729;ii++){
        for(int jj=0;jj<delcols.size();jj++){
            if(exactcover[ii][delcols[jj]].f==1){
                // need to delete that row
                row[ii]=1;
            }
        }
    }

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

    print2d(sudoku);


    cout<<exactcover.size()<<endl;
    cout<<exactcover[0].size()<<endl;

    vector< vector <  pair< int , pair <int , int> > > > empty;
    vector< vector <  pair< int , pair <int , int> > > > soln = algX(exactcover , exactcover.size() , exactcover[0].size() , empty);
    cout<<"soln is"<<endl;
    cout<<soln.size()<<endl;
    int sdk,bdk,cdk,edk,fdk;
    for(int ii=0;ii<soln.size();ii++){
        for(int jj=0;jj<81;jj++){
            if(soln[ii][jj].f == 1){
                // add an element 
                sdk = (soln[ii][jj].s).f ; // row no as stored in exact cover matrix
                sdk = sdk-1;
                bdk = sdk/100; // the no to put
                cdk = sdk%100;
                edk = cdk/9; // row index of sudoku
                fdk = cdk%9; // col index of sudoku
                sudoku[edk][fdk]=bdk;
                cout<<edk<<" "<<fdk<<" "<<bdk<<endl;
            }
        }
    }
    print2d(sudoku);
    //print2(soln);



    




    

    fin.close();

    cudaEventRecord(stop,0);
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&milliseconds, start, stop);
    printf("Time taken by function to execute is: %.6f ms\n", milliseconds);

    
    return 0;
}