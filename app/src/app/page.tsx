'use client';

import { useEffect, useState } from 'react';
import { AppLayout } from '@/components/AppLayout';
import { KPICard } from '@/components/KPICard';
import { Chart } from '@/components/Chart';
import { DataTable } from '@/components/DataTable';
import { AskAI } from '@/components/AskAI';
import { ActionMemo } from '@/components/ActionMemo';
import { GeoMap } from '@/components/GeoMap';

interface DemoNarrative {
  title: string;
  duration: string;
  thesis: string;
  tabs: any[];
}

export default function HomePage() {
  const [narrative, setNarrative] = useState<DemoNarrative | null>(null);
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    fetch('/demo_narrative.json')
      .then((r) => r.json())
      .then(setNarrative)
      .catch(() => {});
    fetch('/api/data')
      .then((r) => r.json())
      .then(setData)
      .catch(() => {});
  }, []);

  const title = narrative?.title || 'SEA AWS Demo';

  const executiveCockpit = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <KPICard title="Production Output" value="12.4M pcs" status="neutral" />
        <KPICard title="Line Efficiency" value="84%" status="neutral" />
        <KPICard title="Quality Pass Rate" value="97.2%" status="neutral" />
        <KPICard title="Workers Active" value="8,400" status="neutral" />
      </div>
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
        <div className="lg:col-span-1">
          <GeoMap
            country="vietnam"
            markers={[{"label": "Ho Chi Minh City", "value": "HQ + export", "color": "blue", "size": "lg"}, {"label": "Binh Duong", "value": "Factory cluster", "color": "green", "size": "lg"}, {"label": "Long An", "value": "Dyeing & finishing", "color": "amber", "size": "md"}, {"label": "Hanoi", "value": "Northern factories", "color": "green", "size": "md"}, {"label": "Da Nang", "value": "Central hub", "color": "green", "size": "sm"}]}
            routes={[{"from": "Binh Duong", "to": "Ho Chi Minh City", "color": "#29B5E8"}]}
            title="Geographic Overview"
            height={280}
          />
        </div>
        <div className="lg:col-span-2 grid grid-cols-1 gap-4">
      <div className="grid grid-cols-1 gap-4 grid-cols-1">
        <Chart
          data={data?.timeseries || [{ period: 'Loading', value: 0 }]}
          type="line"
          xKey="period"
          yKeys={[{ key: 'value', name: 'Pieces (K)' }]}
          title="Daily Production Output"
        />
        <Chart
          data={data?.categories || [{ category: 'Loading', count: 0 }]}
          type="bar"
          xKey="category"
          yKeys={[{ key: 'count', name: '%' }]}
          title="Efficiency by Line"
        />
      </div>
        </div>
      </div>
      <DataTable
        columns={[
          { key: 'id', header: 'Line' },
          { key: 'name', header: 'Style' },
          { key: 'status', header: 'Status' },
          { key: 'value', header: 'Efficiency %' },
        ]}
        data={data?.entities || []}
        title="Production Line Status"
      />
    </div>
  );

  const domainTab1 = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <KPICard title="SAM Achievement" value="92%" />
        <KPICard title="Changeover Time" value="2.4 hrs" />
        <KPICard title="Absenteeism" value="4.8%" />
      </div>
      <Chart
        data={data?.detail || [{ x: 'Loading', y: 0 }]}
        type="area"
        xKey="x"
        yKeys={[{ key: 'y', name: 'Efficiency %' }]}
        title="Efficiency Improvement Trend"
        height={400}
      />
    </div>
  );

  const domainTab2 = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Chart
          data={data?.breakdown || [{ label: 'A', value: 30 }, { label: 'B', value: 70 }]}
          type="pie"
          xKey="label"
          yKeys={[{ key: 'value', name: 'Pieces (K)' }]}
          title="Capacity vs Demand (8-week)"
        />
        <ActionMemo
          persona={{ name: 'Tran Minh Quang', role: 'Factory Director' }}
          context={{}}
          onGenerate={async () => ({
            subject: 'Action Required',
            body: 'AI-generated recommendation based on current data patterns and predicted trends.',
            urgency: 'HIGH',
            actions: ['Balance Line-7 (bottleneck at collar station)', 'Assign experienced operators for Nike tech-pack launch', 'Deploy IE team to improve Line-12 efficiency (currently 72%)'],
          })}
        />
      </div>
    </div>
  );

  const askAiTab = (
    <div className="h-[600px]">
      <AskAI
        title="Ask AI"
        sampleQuestions={[
          'Which lines are below target efficiency?',
          'Show changeover time trend by style complexity',
          'What is the optimal line loading for next week?',
        ]}
        onSubmit={async (question) => {
          return {
            answer: `[Demo Mode] Response to: "${question}" Connect to Snowflake for live data.`,
            sql: 'SELECT * FROM CURATED.SUMMARY LIMIT 10;',
          };
        }}
      />
    </div>
  );

  const architectureTab = (
    <div className="space-y-6">
      <div className="rounded-lg border border-slate-200 bg-white p-6">
        <h2 className="mb-4 text-lg font-bold text-slate-900">Architecture</h2>
        <p className="mb-4 text-sm text-slate-600">
          This demo runs on Snowflake with optional AWS integration. See the README for the full architecture diagram.
        </p>
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
          <div className="rounded border border-blue-200 bg-blue-50 p-4">
            <h3 className="text-sm font-bold text-blue-800">Snowflake Features</h3>
            <ul className="mt-2 space-y-1 text-sm text-blue-700">
              <li>• Dynamic Tables (5-min refresh)</li>
              <li>• ML Functions (Forecast + Anomaly)</li>
              <li>• Cortex Search + Agent</li>
              <li>• Semantic View + Intelligence</li>
              <li>• Alerts + Notifications</li>
            </ul>
          </div>
          <div className="rounded border border-orange-200 bg-orange-50 p-4">
            <h3 className="text-sm font-bold text-orange-800">AWS Services</h3>
            <ul className="mt-2 space-y-1 text-sm text-orange-700">
              <li>• Amazon S3 (Strategy Docs)</li>
              <li>• Amazon S3 + Kinesis</li>
              <li>• Amazon SNS</li>
              <li>• Amazon QuickSight + Q</li>
            </ul>
          </div>
        </div>
      </div>
      <div className="rounded-lg border border-slate-200 bg-white p-6">
        <h2 className="mb-2 text-lg font-bold text-slate-900">Build Modes</h2>
        <div className="grid grid-cols-2 gap-4">
          <div className="rounded border border-emerald-200 bg-emerald-50 p-3">
            <h4 className="text-sm font-bold text-emerald-800">Snowflake Only</h4>
            <p className="mt-1 text-xs text-emerald-700">All features run natively in Snowflake. No AWS dependencies.</p>
          </div>
          <div className="rounded border border-violet-200 bg-violet-50 p-3">
            <h4 className="text-sm font-bold text-violet-800">Full AWS + Snowflake</h4>
            <p className="mt-1 text-xs text-violet-700">S3, Kinesis, SNS, QuickSight integrated with Snowflake Cortex AI.</p>
          </div>
        </div>
      </div>
    </div>
  );

  const tabs = [
    { id: 'executive-cockpit', label: 'Executive Cockpit', icon: '📊', content: executiveCockpit },
    { id: 'domain-1', label: 'Line Analytics', icon: '📈', content: domainTab1 },
    { id: 'domain-2', label: 'Planning', icon: '⚡', content: domainTab2 },
    { id: 'ask-ai', label: 'Ask AI', icon: '🤖', content: askAiTab },
    { id: 'architecture', label: 'Architecture & Data', icon: '🏗️', content: architectureTab },
  ];

  return (
    <AppLayout
      title={title}
      subtitle="Powered by Snowflake + AWS"
      tabs={tabs}
      narrative={narrative}
    />
  );
}
