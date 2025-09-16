module MyModule::PrivateVoting {
    use aptos_framework::signer;
    use std::vector;
    
    /// Struct representing a class poll with anonymous voting
    struct Poll has store, key {
        question: vector<u8>,     // Poll question as bytes
        option_a_votes: u64,      // Votes for option A
        option_b_votes: u64,      // Votes for option B
        total_votes: u64,         // Total number of votes cast
        is_active: bool,          // Whether voting is still open
    }
    
    /// Struct to track if an address has already voted (prevents double voting)
    struct VoterRecord has store, key {
        has_voted: bool,
    }
    
    /// Function to create a new poll with a question and two options
    /// Only the poll creator can call this function
    public fun create_poll(creator: &signer, question: vector<u8>) {
        let poll = Poll {
            question,
            option_a_votes: 0,
            option_b_votes: 0,
            total_votes: 0,
            is_active: true,
        };
        move_to(creator, poll);
    }
    
    /// Function for users to cast their vote anonymously
    /// vote_option: true for option A, false for option B
    public fun cast_vote(
        voter: &signer, 
        poll_creator: address, 
        vote_option: bool
    ) acquires Poll, VoterRecord {
        let voter_addr = signer::address_of(voter);
        
        // Check if voter has already voted
        if (exists<VoterRecord>(voter_addr)) {
            let voter_record = borrow_global<VoterRecord>(voter_addr);
            assert!(!voter_record.has_voted, 1); // Error code 1: Already voted
        } else {
            // Create voter record if it doesn't exist
            let voter_record = VoterRecord { has_voted: false };
            move_to(voter, voter_record);
        };
        
        // Get the poll and update vote counts
        let poll = borrow_global_mut<Poll>(poll_creator);
        assert!(poll.is_active, 2); // Error code 2: Poll is closed
        
        if (vote_option) {
            poll.option_a_votes = poll.option_a_votes + 1;
        } else {
            poll.option_b_votes = poll.option_b_votes + 1;
        };
        
        poll.total_votes = poll.total_votes + 1;
        
        // Mark voter as having voted
        let voter_record = borrow_global_mut<VoterRecord>(voter_addr);
        voter_record.has_voted = true;
    }
}