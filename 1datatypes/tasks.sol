
pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

contract taskContract {
    struct task {
        string name;
        uint32 timestamp;
        bool complete;
    }
    mapping(int8=>task) tasks;
    int8 counter = 0;

    constructor() public {
        require(tvm.pubkey() != 0, 101);
        require(msg.pubkey() == tvm.pubkey(), 102);
        tvm.accept();
    }
    modifier taskexists(int8 id) {
        require(tasks.exists(id), 101, 'task does not exist');
        _;
    }
    modifier tasksexist() {
        require(counter > 0, 100, 'list is empty');
        _;
    }

    function add(string task_name, bool is_complete) public {
        tasks[counter] = task(task_name, now, is_complete);
        counter += 1;
        tvm.accept();
    }

    function incompletes() public view tasksexist returns (int8) {
        tvm.accept();
        int8 newcounter = 0;
        for(int8 i = 0; i < counter; i++) {
            if (tasks.exists(i) && !tasks[i].complete) {
                newcounter += 1;
            }
        }
        return newcounter;
    }

    function tasklist() public view tasksexist returns (mapping(int8=>task)) {
        tvm.accept();
        return tasks;
    }

    function description(int8 id) public view tasksexist taskexists(id) returns (string) {
        tvm.accept();
        return tasks[id].name;
    }

    function deletetask(int8 id) public tasksexist taskexists(id) {
        tvm.accept();
        delete tasks[id];
    }

    function markcomplete(int8 id) public tasksexist taskexists(id) {
        tvm.accept();
        tasks[id].complete = true;
    }
}
