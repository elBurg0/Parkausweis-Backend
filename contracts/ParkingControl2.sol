// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract ParkingControl {
    address private _owner;
    mapping(address => bool) allowed_confirmers;
    mapping(address => bool) allowed_workers;

    constructor (){
        _owner = msg.sender;
        allowed_confirmers[_owner] = true;
        allowed_workers[_owner] = true;
    }

    struct Request {
        address req_address;
        string place;
        bool is_init;
    }

    struct Ticket {
        address ticket_owner;
        string place;
        uint256 exp_date;
        bool is_visitor;
        bool is_valid;
    }

    mapping(string => Request) public requests;
    mapping(address => string) public req_address_plates;

    mapping(string => Ticket) public tickets;
    mapping(address => string) public address_plates;
    mapping(address => string) public address_visitorplates;

    function claimParkingPass(string memory numbersplate, string memory place) public {
        require(bytes(numbersplate).length != 0 || bytes(place).length != 0, "Can't claim parking pass without numbersplate or place");
        require(!(requests[numbersplate].is_init), "Already requested ticket for this plate");
        require(bytes(req_address_plates[msg.sender]).length == 0, "Already requested ticket with this address");
        
        req_address_plates[msg.sender] = numbersplate;

        requests[numbersplate] = Request(
            msg.sender,
            place,
            true
        );
    }

    function deleteRequest(string memory numbersplate) public {
        require(allowed_confirmers[msg.sender], "Insufficient permissions");
        require(requests[numbersplate].is_init, "No request for this plate");

        delete requests[numbersplate];
    }

    function confirmParkingPass(string memory numbersplate) public {
        require(allowed_confirmers[msg.sender], "Insufficient permissions");
        require(requests[numbersplate].is_init, "No request for this plate");

        uint exp_date = block.timestamp + 365 days;

        // get request
        Request memory req = requests[numbersplate];
        // add address to mapping with plate
        address_plates[req.req_address] = numbersplate;

        tickets[numbersplate] = Ticket(
            req.req_address,
            req.place,
            exp_date,
            false,
            true
        );

        delete requests[numbersplate];
    } 

    function verifyParkingPass(string memory numbersplate) public view returns (Ticket memory){
        require(allowed_workers[msg.sender], "Insufficient permissions");
        require(tickets[numbersplate].is_valid, "Plate not valid");
        require(tickets[numbersplate].exp_date > block.timestamp, "Ticket exceeded");

        return tickets[numbersplate];
    }

    function claimVisitorPass(string memory numbersplate_visitor) public {
        string memory parent_plate = address_plates[msg.sender];
        require(tickets[parent_plate].is_valid, "No valid main ticket for current wallet");

        // calculate expiring date of visitor ticket
        uint exp_date = block.timestamp + 60 days;

        // if wallet has created a visitor plate, check if its still valid
        if(bytes(address_visitorplates[msg.sender]).length != 0) {
            if(tickets[address_visitorplates[msg.sender]].exp_date > block.timestamp){
                // If visitor ticket is still valid, revert transaction
                revert("Address already has an active visitor ticket");
            } else {
                // If visitor ticket isn't valid anymore, delete it and proceed
                delete tickets[address_visitorplates[msg.sender]];
            }
        }

        // get main ticket
        Ticket memory parent_ticket = tickets[parent_plate];

        // check if calculated due date of visitor ticket is past due date of main ticket
        if (exp_date > parent_ticket.exp_date){
            // if so, set exp_date to the exp_date of the main ticket
            exp_date = parent_ticket.exp_date;
        }

        // insert new visitor plate
        address_visitorplates[msg.sender] = numbersplate_visitor;

        // insert new ticket for visitor
        tickets[numbersplate_visitor] = Ticket(
            msg.sender,
            parent_ticket.place,
            exp_date,
            true,
            true
        );
    }

     function renewParkingPass() public {
        string memory plate = address_plates[msg.sender];
        require(tickets[plate].is_valid, "No valid ticket for current wallet");

        Ticket memory parent_ticket = tickets[plate];

        claimParkingPass(plate, parent_ticket.place);
    }

    function addConfirmer(address conf_address) public {
        require(msg.sender == _owner, "Insufficient permissions");
        allowed_confirmers[conf_address] = true;
    }

    function addWorker(address worker_address) public {
        require(msg.sender == _owner, "Insufficient permissions");
        allowed_workers[worker_address] = true;
    }

}
