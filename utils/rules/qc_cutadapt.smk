rule fastqcRaw:
    input:
        unpack( lambda wc: dict(SampleTable.loc[wc.sample]))
    output:
        R1= config["output_dir"] + "/fastqc_raw/{sample}" + config["R1"] + "_fastqc.html",
        R2= config["output_dir"] + "/fastqc_raw/{sample}" + config["R2"] + "_fastqc.html"
    conda:
        "QC"
    params:
          output=config["output_dir"]+ "/fastqc_raw"
    shell: "fastqc -o {params.output} {input.R1} {input.R2} "


rule multiqcRaw:
    input:
        R1 =expand(config["output_dir"]+"/fastqc_raw/{sample}" + config["R1"] +"_fastqc.html",sample=SAMPLES),
        R2 =expand(config["output_dir"]+"/fastqc_raw/{sample}" + config["R2"] +"_fastqc.html",sample=SAMPLES)
    output:
        config["output_dir"]+"/multiqc_raw/multiqc_report_raw.html"
    conda:
        "QC"
    params:
        fastqc_dir=config["output_dir"]+"/fastqc_raw",
        multiqc_dir=config["output_dir"]+"/multiqc_raw",
        multiqc_html="multiqc_report_raw.html"
    shell: 
        "multiqc -f {params.fastqc_dir} -o {params.multiqc_dir} -n {params.multiqc_html} "



rule cutAdapt:
    input:
        unpack( lambda wc: dict(SampleTable.loc[wc.sample]))
    output:
        R1= config["output_dir"]+"/cutadapt/{sample}" + config["R1"] + ".fastq.gz",
        R2= config["output_dir"]+"/cutadapt/{sample}" + config["R2"] + ".fastq.gz"
    params:
       inputs= lambda wc,input: f"{input.R1} {input.R2}",
        m=config["min_len"],
        o=config["min_overlap"],
        e=config["max_e"]
    threads:
        config['threads']
    conda:
        "QC"
    shell:
        "cutadapt -m {params.m} -O {params.o} " 
#       "-g {config[fwd_primer]} -G {config[rev_primer]} -a {config[rev_primer_rc]} -A {config[fwd_primer_rc]}"
        " -o {output.R1} -p {output.R2} "
        "{params.inputs} "

rule cutAdaptQc:
    input:
        R1= rules.cutAdapt.output.R1,
        R2= rules.cutAdapt.output.R2
    output:
        R1= config["output_dir"]+"/cutadapt_qc/{sample}" + config["R1"] + ".fastq.gz",
        R2= config["output_dir"]+"/cutadapt_qc/{sample}" + config["R2"] + ".fastq.gz"
    params:
        qf=config["qf"],
        qr=config["qr"],
        m=config["min_len"]
    threads:
        config['threads']
    conda:
        "QC"
    shell:
        "cutadapt -A XXX -q {params.qf},{params.qr} -m {params.m} -o {output.R1} -p {output.R2} {input.R1} {input.R2} "



rule fastqcFilt:
    input:
        R1= rules.cutAdaptQc.output.R1,
        R2= rules.cutAdaptQc.output.R2
    output:
        R1= config["output_dir"]+"/fastqc_filt/{sample}"+ config["R1"] + "_fastqc.html",
        R2= config["output_dir"]+"/fastqc_filt/{sample}"+ config["R2"] + "_fastqc.html"
    conda:
        "QC"
    params:
         fastqc_dir=config["output_dir"]+ "/fastqc_filt"
    shell: 
        "fastqc -o {params.fastqc_dir} {input.R1} {input.R2} " 



rule multiqcFilt:
    input:
        R1= expand(config["output_dir"]+"/fastqc_filt/{sample}"+ config["R1"] + "_fastqc.html",sample=SAMPLES),
        R2= expand(config["output_dir"]+"/fastqc_filt/{sample}"+ config["R2"] + "_fastqc.html",sample=SAMPLES)
    output:
        config["output_dir"]+"/multiqc_filt/multiqc_report_filtered.html"
    conda:
        "QC"
    params:
        fastqc_dir=config["output_dir"]+"/fastqc_filt",
        multiqc_dir=config["output_dir"]+"/multiqc_filt",
        multiqc_html="multiqc_report_filtered.html"
    shell: 
        "multiqc -f {params.fastqc_dir} -o {params.multiqc_dir} -n {params.multiqc_html}"
