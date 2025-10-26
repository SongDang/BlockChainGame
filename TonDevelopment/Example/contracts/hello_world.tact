
message Add {
    amount: Int as uint32;
}

const NANO: Int = 1000000000; // 1 TON = 10^9 basic units
message Deposit {}               // send TON to get score
message Reward { to: Address; amount: Int as uint128; } // owner reward amount 
message GetScore { player: Address; }

contract HelloWorld(
    // Persistent state variables declared via the
    // contract parameters syntax, which was introduced in v1.6.0
    //
    // See: https://docs.tact-lang.org/book/contracts/#parameters
    id: Int as uint32,
    counter: Int as uint32,



    // owner address 
    owner: Address,
    // rate: how many score per 1 TON (not per basic unit)
    ratePerTon: Int as uint32,    // pass 100 for 1 TON => 100 score
    // persistent mapping: player address -> score
    scores: map<Address, Int>
) {

    // Empty receiver for the deployment,
    // which expects the `null` message body
    // receive() {
    //     // Forward the remaining value in the
    //     // incoming message back to the sender
    //     cashback(sender());
    // }
    receive(msg: Add) {
        self.counter += msg.amount;

        // Forward the remaining value in the
        // incoming message back to the sender
        // cashback(sender());
    }
    get fun counter(): Int {
        return self.counter;
    }
    get fun id(): Int {
        return self.id;
    }


    // helper: require owner
    fun onlyOwner() {
        require(sender() == self.owner,"OnlyOwner!"); // error if not owner
    }

    // default receive without message: treat as Deposit
    receive() {
        // value() returns amount of basic units sent with message
        let paid: Int = context().value;


        // compute score increment:
        // scoreInc = floor( (paid / NANO) * ratePerTon )
        // compute integer: (paid * ratePerTon) / NANO
        let scoreInc: Int = (paid * self.ratePerTon) / NANO;

        // add to player's score
        let p: Address = sender();
        let prevTemp: Int? = self.scores.get(p);
        let prev: Int = 0;

        //Check null value, convert to Int
        if (prevTemp == null) {
            prev = 0;
        }
        else {
            prev = prevTemp!!;
        }

        self.scores.set(p, prev + scoreInc);

        // keep the money in contract (no cashback) — contract balance increases
    }

    // explicit Deposit message (identical to bare receive)
    receive(msg: Deposit) {
        let paid: Int = context().value;
        let scoreInc: Int = (paid * self.ratePerTon) / NANO;
        let p: Address = sender();
        let prevTemp: Int? = self.scores.get(p);
        let prev: Int = 0;

        if (prevTemp == null) {
            prev = 0;
        }
        else {
            prev = prevTemp!!;
        }
        self.scores.set(p, prev + scoreInc);
    }

    // Owner rewards a player: transfers TON (basic units) from contract balance to player
    receive(msg: Reward) {
        self.onlyOwner();

        // amount is in basic units (same unit as value())
        let amount: Int = msg.amount;

        // Basic safety: check contract has enough balance
        // balance() returns current contract balance (basic units)
        require(myBalance() >= amount, "Insufficient"); // error if insufficient

        // transfer amount to player
        send(SendParameters{
            to: msg.to,
            value: amount,
            bounce: true, // Optional: Message will bounce back on error (default behavior)
            mode: SendRemainingValue, // Optional: Recommended mode for transfers
        });
    }

    // Query player's score (getter)
    get fun get_score(p: Address): Int {
        let scorePlayer: Int? = self.scores.get(p);
        if(scorePlayer == null) {
            return 0;
        }
        return scorePlayer!!;
    }

    // Query contract balance (basic units)
    get fun get_balance(): Int {
        return myBalance();
    }

    // Query owner
    get fun get_owner(): Address {
        return self.owner;
    }

    // Query rate
    get fun get_rate(): Int {
        return self.ratePerTon;
    }
}
