function transform_record_Q(id) {
    if (length(record_ids) == 0) {
        # true - default is to transform all records
        1
    } else if (NR in valuesAsKeys) {
        # true - transform this record
        1
    } else {
        # false - do not transform this record
        0
    }
}

function print_transformed_or_raw_record(id) {
    if (transform_record_Q(id)) {
        printf "%s", $0 |& cmd;
    } else {
        printf "%s", $0
    }
}

function print_transformed_or_raw_record_with_irs(id) {
    if (transform_record_Q(id)) {
        printf "%s%s", rs_unesc, $0 |& cmd;
    } else {
        printf "%s%s", rs_unesc, $0
    }
}

BEGIN {
    if (length(record_ids) == 0) {
        split(record_ids,record_ids_vals,",")
        for (i in record_ids_vals) record_ids_keys[record_ids_vals[i]] = ""
    }
    print cmd
}

{
    # print NR
    if (r == "" || NR == r) {
        if (NR == 1) {
            print_transformed_or_raw_record(NR)
        } else {
            if (irs == "y") {
                printf "%s", rs_unesc
                printf "%s", $0 |& cmd;
                print_transformed_or_raw_record(NR)
            } else {
                print_transformed_or_raw_record_with_irs(NR)
            }
        }

        close(cmd, "to");

        # This is needed because getline will not overwrite if nothing is read
        $0 = "";

        cmd |& getline $0;

        fflush(cmd);
        close(cmd);

    } else {
        if (NR > 1) {
            print RS
        }
    }

    print; system("");
}
