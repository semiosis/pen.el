#!/usr/bin/env crun

#include <linux/slab.h>
#include <linux/types.h>
#include <linux/unistd.h>
#include "sched.h"
#include "sched1.h"
int process_init(void)
{
    printk(KERN_INFO "lOADING  MODULE \n");
    printk(KERN_INFO "PID \t PPID \t PNAME \t SIZE \n");
    struct task_struct *task;
    struct mm_struct *mm;
    for_each_process(task)
    {
        mm = get_task_mm(task);
        printk(KERN_INFO "%d \t %d\t %s \t %d \n",
                task->pid, task_ppid_nr(task), task->comm, mm->total_vm);
    }

    return 0;
}
