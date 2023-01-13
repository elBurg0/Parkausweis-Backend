// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract ParkingControl {
    mapping(address => bool) allowed_editors;
    mapping(address => bool) allowed_confirmers;
    mapping(address => bool) allowed_workers;

    constructor (){
        allowed_editors[address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4)] = true;
        allowed_confirmers[address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4)] = true;
        allowed_workers[address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4)] = true;
    }

     event NewRequest(
        address indexed requestAdress,
        string numbersplate,
        string place
    );

    struct Request {
        string numbersplate;
        string place;
        bool is_init;
    }

    struct ParkingTicket {
        string numbersplate;
        string place;
        uint256 date_confirmed;
        bool is_valid;
    }

    mapping(address => Request) public requests;
    mapping(address => ParkingTicket) public tickets;
    mapping(address => ParkingTicket) public ticketsVisitor;
    mapping(string => address) public plates;

    function claimParkingPass(string memory numbersplate, string memory place) public {
        require(bytes(numbersplate).length != 0 || bytes(place).length != 0, "can't claim parking pass without numbersplate or place");
        // Check if plate not in plates

        requests[msg.sender] = Request(
            numbersplate,
            place,
            true
        );

        plates[numbersplate] = msg.sender;

        // Emit a NewRequest event with details about the request.
        emit NewRequest(
            msg.sender,
            numbersplate,
            place
        );
    }

    function confirmParkingPass(address req_address, uint256 date) public {
        require(allowed_confirmers[msg.sender], "Insufficient permissions");
        require(requests[req_address].is_init, "No request from this address"); 

        Request memory req = requests[req_address];

        tickets[req_address] = ParkingTicket(
            req.numbersplate,
            req.place,
            date,
            true
        );
    } 

    function verifyParkingPass(string memory numbersplate) public view returns (ParkingTicket memory){
        require(allowed_confirmers[msg.sender], "Insufficient permissions");
        require(tickets[plates[numbersplate]].is_valid || ticketsVisitor[plates[numbersplate]].is_valid, "Plate not valid"); 

        if(tickets[plates[numbersplate]].is_valid){
            return tickets[plates[numbersplate]];
        } 
        return ticketsVisitor[plates[numbersplate]];
    }

    function claimVisitorPass(string memory numbersplate, uint256 date) public {
        require(allowed_confirmers[msg.sender], "Insufficient permissions");
        require(tickets[msg.sender].is_valid);

        ParkingTicket memory parent_ticket = tickets[msg.sender];

        if (date > parent_ticket.date_confirmed){
            date = parent_ticket.date_confirmed;
        }

        ticketsVisitor[msg.sender] = ParkingTicket(
            numbersplate,
            parent_ticket.place,
            date,
            true
        );

        plates[numbersplate] = msg.sender;
    }

     function renewParkingPass() public {
        Request memory old_req = requests[msg.sender];
        delete requests[msg.sender];

        claimParkingPass(old_req.numbersplate, old_req.place);
    }

    
}
