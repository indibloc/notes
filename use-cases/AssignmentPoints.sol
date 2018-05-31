pragma solidity ^0.4.24;


/** @title Assigns Points to the IndiBloc S2018 cohort. 
    version v0.01 - 31-may-2018
*/
contract AssignPoints {
    struct Assignment {
        uint id;
        string url;
        uint    maxPoints;
        bool  isLive ;
    }
    struct Assessment {
        address mentor;
        address cohort;
        uint  assignmentId;
        uint    points;
    }
    // admin creates the contract
    address  admin;
    address[] public mentors;
    bool  isLive ;
    address[]  public cohorts;
    Assignment[] public assignments; 
    Assessment[] public assessments;
    
    modifier onlyAdmin() { // Modifier
        require(
            msg.sender == admin,
            "Only admin can call this."
        );
        _;  // function content being modified is placed here
    }
    
    constructor() public {
        admin = msg.sender;
        isLive = true;
    }
    function checkIfOpen() public view returns ( bool)  {
        return isLive;
    }
    
    function close( ) public onlyAdmin {
        isLive = false;
    }
    
    function addMentor(address mentor) public onlyAdmin {
       require(!isMentor(mentor), "Already a mentor" );    
       mentors.push(mentor);
        
    }
    function addMentors(address[] mentorz) public onlyAdmin {
   
       for(uint i=0; i < mentorz.length; i++) 
          addMentor(mentorz[i]);
        
    }
    function addCohort(address cohort) public onlyAdmin {
       require(!isMentor(cohort), "Already in cohort" );      
       cohorts.push(cohort);
    }
    function addCohorts(address[] cohortz) public onlyAdmin {
   
       for(uint i=0; i < cohortz.length; i++) 
          addMentor(cohortz[i]);
        
    }    
    function addAssignment(uint id,string url, uint maxPoints) 
        public onlyAdmin 
        returns (bool)
    {
        for(uint i=0; i < assignments.length; i++) {
            if(assignments[i].id == id)   
              return false;
        }
        Assignment memory assign = Assignment(id, url, maxPoints,true);
        assignments.push(assign);
        return true;
    }
    function closeAssignment(uint id) public onlyAdmin returns (bool) {
      for(uint i=0; i < assignments.length; i++) {
            if(assignments[i].id == id)  { 
               assignments[i].isLive = false;
              return true;
            }
        }       
        
      return false;
    }
    function assess(address cohort, uint  assignmentId, uint    points) public {
        require(isLive, "SprintUp accessement closed");
        require(isAssignmentValid(assignmentId), "Invalid assignment");
        require(isMentor(msg.sender), "Not a mentor");
        require(!assessed(msg.sender, cohort, assignmentId), "already accessed");
        Assessment memory ax  =  Assessment(
                                   msg.sender, 
                                   cohort, 
                                   assignmentId, 
                                   points
                                );
        assessments.push(ax);
                                
    }
    function isMentor(address mentor) public view returns (bool) {
         for(uint i=0; i < mentors.length; i++) {
             if(mentors[i] == mentor) 
                return true;
         }
          return false;
    }
    function isCohort(address cohort)  public view returns (bool) {
        for(uint i=0; i < cohorts.length; i++) {
            if(cohorts[i] == cohort)
                return true;
        }
        return false;
    }
    function assessed(address mentor, address cohort, uint assignmentId)  public view returns (bool) {
        for(uint i=0; i < assessments.length; i++) {
            if(assessments[i].mentor == mentor &&
               assessments[i].cohort == cohort &&
               assessments[i].assignmentId == assignmentId 
            )
            return true;
        }
        return false;
    }
    function isAssignmentValid(uint assignmentId)  public view returns (bool) {
        if(!isLive)
           return false;
        for(uint i=0; i < assignments.length; i++) {
            if(assignments[i].id == assignmentId && assignments[i].isLive)
            return true;
        }
        return false;   
    }
}


